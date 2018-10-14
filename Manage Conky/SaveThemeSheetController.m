//
//  SaveThemeSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Shared.h"
#import "ViewController.h"
#import <Fragaria/Fragaria.h>
#import "MCObjects/MCObjects.h"
#import "SaveThemeSheetController.h"
#import "SaveWidgetSheetController.h"
#import "Extensions/NSString+Empty.h"
#import "Extensions/NSAlert+runModalSheet.h"

enum {
    MC_FROM_LIST = 0,
    MC_FROM_DIRECTORY
};

/*
 * Registry of checkboxes
 */
static NSMutableArray<Checkbox *> *checkboxRegistry = nil;
NSUInteger fromListWidgetsCount = 0;    /* the -fromList- widgets */

@implementation Checkbox
+ (instancetype)checkboxForWidget:(NSString *)widget
{
    /* check if registry has already been created */
    if (checkboxRegistry)
    {
        /* Try to find an entry corresponding to this widget! */
        for (Checkbox *cb in checkboxRegistry)
            if ([[cb widget] isEqualToString:widget])
                return cb;  /* return one from registry */
    }
    else
        checkboxRegistry = [NSMutableArray arrayWithCapacity:fromListWidgetsCount];
    
    /*
     * either registry hadn't been created yet or we didn't find an entry;
     * create one
     */
    id entry = [[Checkbox alloc] init];
    if (entry)
    {
        [entry setWidget:widget];
        
        /* publish ourselves to registry */
        [checkboxRegistry addObject:entry];
    }
    return entry;
}
@end

@implementation CheckboxEventListener
- (IBAction)click:(id)sender
{
    NSTableView *tableView = (NSTableView *)[[[sender superview] superview] superview];
    NSTableCellView *cellView = (NSTableCellView *)[sender superview];
    NSUInteger row = [tableView rowForView:cellView];
    
    checkboxRegistry[row].state = [(NSButton *)sender state];
}
@end

@implementation SaveThemeSheetController
- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    if (self)
    {
        /*
         * Basic initialisation
         */
        _scaling = FillScreen;
        _relative = YES;
        
        _conkyConfigs = [NSMutableArray array];
        fromListWidgets = [NSMutableArray array];
        fromDirectoryWidgets = [NSMutableArray array];
        searchDirectories = [NSMutableArray array];
        
        /*
         * Our ViewController already contains the infrastructure
         * for getting the list of widgets in a directory; Use it
         * to speed things up.
         */
        ViewController *vc = [[ViewController alloc] init];
        [vc fillWidgetsThemesArrays];
        
        for (MCWidget *widget in vc.widgets)
        {
            [fromListWidgets addObject:widget.itemPath];
        }
        
        [_widgetsTableView setDelegate:self];
        [_widgetsTableView setDataSource:self];

        selectedView = MC_FROM_LIST;
    }
    return self;
}

- (void)awakeFromNib
{
    /* popup button */
    for (int i = 0; i < MAX_SCALING_KEYS; i++)
        [_scalingPopUpButton addItemWithTitle:[NSString stringWithUTF8String:cMacScalingKeys[i]]];

    [_widgetsTableView registerForDraggedTypes:@[NSFilenamesPboardType]]; /*  we only accept files with no-extension*/
}

- (IBAction)chooseWallpaper:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowedFileTypes = @[@"png", @"jpg", @"tiff"];
    
    /*
     * display the panel
     */
    if ([panel runModal] == NSModalResponseOK)
    {
        _wallpaper = [[[panel URLs] objectAtIndex:0] path];
        
        [_wallpaperPathLabel setStringValue:_wallpaper];
        [_wallpaperPathLabel setTextColor:[NSColor grayColor]];
        [_wallpaperPathLabel setHidden:NO];
    }
    else
        return;

    /*
     * Keep path relative to theme directory OR full?
     */
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Relative or Absolute path?";
    alert.informativeText = @"Choosing Relative path will make your Theme Portable!";
    [alert addButtonWithTitle:@"Relative"];
    [alert addButtonWithTitle:@"Absolute"];
    
    switch ([alert runModal])
    {
        case NSAlertFirstButtonReturn:
            _relative = YES;
            break;
        case NSAlertSecondButtonReturn:
        default:
            _relative = NO;
            break;
    }
}

- (IBAction)chooseScaling:(id)sender
{
    _scaling = [sender indexOfSelectedItem];
}

- (IBAction)changeTableView:(id)sender
{
    if ([sender selectedSegment] == MC_FROM_DIRECTORY)
    {
        NSOpenPanel *op = [NSOpenPanel openPanel];
        [op setCanChooseFiles:NO];
        [op setCanChooseDirectories:YES];
        [op setAllowsMultipleSelection:NO];
        [op setMessage:@"Select Directory with Widgets"];

        if ([op runModal] == NSModalResponseOK)
        {
            [searchDirectories addObject:op.URL.path];
            
            for (NSString *item in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:op.URL.path error:nil])
            {
                [fromDirectoryWidgets addObject:item];
            }
        }
    }
    
    selectedView = [sender selectedSegment];

    [_widgetsTableView reloadData];
}

//
//=========================================================================================================
//

- (IBAction)createWidgetRightNow:(id)sender
{
    /*
     * Introduce a new search-directory and create the widget there!
     */
    
    /*
     * Initialise editor controller
     */
    [[[SaveWidgetSheetController alloc] initWithWindowNibName:@"SaveWidget"] loadOnWindow:self.window];
    
    /*
     * Reload the "From List" list
     */
    
    /*
     * Now mark it! (With green colour) XXX is this possible?
     */
}

//
//=========================================================================================================
//


// HELPER
- (NSMutableArray *)getConkyConfigsFrom:(NSMutableArray *)widgetsFromList and:(NSMutableArray *)widgetsFromDirectories
{
    NSMutableArray *arr = [NSMutableArray array];
    
    /* Only take user-selected widgets */
    for (Checkbox *cb in checkboxRegistry)
        if ([fromListWidgets doesContain:[cb widget]] && ([cb state] == NSOnState))
            [arr addObject:[cb widget]];
    
    [arr addObjectsFromArray:widgetsFromDirectories];
    return arr;
}

- (IBAction)saveTheme:(id)sender
{
    // DBG
    NSLog(@"These are all the widgets from List (+ accepted?)");
    for (Checkbox *cb in checkboxRegistry)
    {
        NSLog(@"%@: %i", [cb widget], [cb state]);
    }
    
    /*
     * Set the values
     */
    _name = _themeNameField.stringValue;
    _source = _themeSourceField.stringValue;
    _creator = _themeCreatorField.stringValue;
    _conkyConfigs = [self getConkyConfigsFrom:fromListWidgets and:fromDirectoryWidgets];
    
    if (_name.empty || _source.empty || _creator.empty || !_wallpaper || !_conkyConfigs || ([_conkyConfigs count] == 0))
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Whoah! Hold your horses!"];
        [alert setInformativeText:@"You forgot to fill in some info."];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModalSheetForWindow:self.window];
        return;
    }
    
    /* get PROPER rect for our text */
    NSTextField *dummyField = [NSTextField textFieldWithString:[_conkyConfigs componentsJoinedByString:@"\n"]];
    NSRect editorFieldRect = dummyField.bounds;
    
    /* create fragaria view */
    MGSFragariaView *mgs = [[MGSFragariaView alloc] initWithFrame:editorFieldRect];
    [mgs setString:[_conkyConfigs componentsJoinedByString:@"\n"]];
    [mgs setShowsLineNumbers:NO];
    
    /* prompt user whether to continue or not */
    NSAlert *approveWidgets = [[NSAlert alloc] init];
    [approveWidgets setMessageText:@"Are you sure you want these Widgets in your Theme?"];
    [approveWidgets setAccessoryView:mgs];
    [approveWidgets setAlertStyle:NSAlertStyleCritical];
    [approveWidgets addButtonWithTitle:@"Actually, No"];
    [approveWidgets addButtonWithTitle:@"Yes"];
    
    if ([approveWidgets runModal] == NSAlertFirstButtonReturn)
        return;
    
    /*
     * User wants to continue; Lets the Theme...
     */
    NSString *basicSearchPath = [[MCSettings sharedInstance] configsLocation];
    NSString *path = [basicSearchPath stringByAppendingPathComponent:_name];
    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];
    
    /*
     * Create Theme directory
     */
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
    {
        NSLog(@"saveTheme: %@", error);
        return;
    }
    
    /* Create ThemeRC */
    if (_relative) [themerc setObject:_wallpaper.lastPathComponent forKey:@"wallpaper"];
    else [themerc setObject:_wallpaper forKey:@"wallpaper"];
    
    [themerc setObject:_conkyConfigs forKey:@"conkyConfigs"];
    [themerc setObject:_source forKey:@"source"];
    [themerc setObject:_creator forKey:@"creator"];
    [themerc setObject:[NSString stringWithUTF8String:cMacScalingKeys[_scaling]] forKey:@"scaling"];
    
    /* Write ThemeRC */
    [themerc writeToFile:[path stringByAppendingPathComponent:@"themerc.plist"]
              atomically:YES];
    
    error = nil;    // re-use
    
    /*
     * Copy Resources
     */
    /* copy widgets */
    for (NSString *widgetPath in _conkyConfigs)
    {
        [[NSFileManager defaultManager] copyItemAtPath:widgetPath toPath:[path stringByAppendingPathComponent:widgetPath.lastPathComponent] error:&error];
        if (error)
        {
            NSLog(@"%@", error);
            error = nil;
        }
    }

    error = nil;    /// re-use

    /* copy wallpaper */
    if (_relative)
    {
        [[NSFileManager defaultManager] copyItemAtPath:_wallpaper toPath:[path stringByAppendingPathComponent:_wallpaper.lastPathComponent] error:&error];
        if (error)
            NSLog(@"saveTheme: %@", error);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
}

//
//=========================================================================================================
//

//
// DATA SOURCE
//

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    fromListWidgetsCount = [fromListWidgets count];
    return (selectedView == MC_FROM_LIST) ? [fromListWidgets count] : [fromDirectoryWidgets count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0)
        return nil;

    if ([[tableColumn identifier] isEqualToString:@"Text"])
    {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Text" owner:nil];
        [[cell textField] setStringValue:(selectedView == MC_FROM_LIST) ? [[fromListWidgets objectAtIndex:row] lastPathComponent] : [fromDirectoryWidgets objectAtIndex:row]];
        return cell;
    }
    else if ([[tableColumn identifier] isEqualToString:@"Checkbox"])
    {
        if (selectedView == MC_FROM_LIST)
        {
            Checkbox *cb = [Checkbox checkboxForWidget:[fromListWidgets objectAtIndex:row]];
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Checkbox" owner:cb];
            return cell;
        }
    }
    
    return nil;
}
@end
