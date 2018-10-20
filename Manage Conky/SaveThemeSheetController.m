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
#import "SaveThemeSheetCheckbox.h"
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
static NSUInteger fromListWidgetsCount = 0; /* the -fromList- widgets */

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
}

- (IBAction)choosePreview:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowedFileTypes = @[@"png", @"jpg", @"tiff"];
    
    /*
     * display the panel
     */
    if ([panel runModal] == NSModalResponseOK)
    {
        _preview = [[[panel URLs] objectAtIndex:0] path];
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
        ViewController *vc = [[ViewController alloc] init];
        [vc createWidgetsArray];
        
        NSOpenPanel *op = [NSOpenPanel openPanel];
        [op setCanChooseFiles:NO];
        [op setCanChooseDirectories:YES];
        [op setAllowsMultipleSelection:NO];
        [op setMessage:@"Select Directory with Widgets"];

        if ([op runModal] == NSModalResponseOK)
        {
            [searchDirectories addObject:op.URL.path];
            
            [vc fillWidgetsThemesArraysWithSearchPath:op.URL.path];
            for (MCWidget *widget in [vc widgets])
                [fromDirectoryWidgets addObject:[widget widgetName]];
        }
    }
    
    selectedView = [sender selectedSegment];

    [_widgetsTableView reloadData];
}

//
//=========================================================================================================
//

- (void)didSaveWidget
{
    
}

- (IBAction)createWidgetRightNow:(id)sender
{
    /*
     * Initialise editor controller
     */
    SaveWidgetSheetController *swsc = [[SaveWidgetSheetController alloc] initWithWindowNibName:@"SaveWidget"];
    [swsc setDelegate:self];    /*
                                 * do stuff ONLY if user ACTUALLY
                                 * created a widget, that is if
                                 * -didSaveWidget is called.
                                 */
    [swsc loadOnWindow:self.window];
}

//
//=========================================================================================================
//

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
     * Select location to save!
     */
    NSString *path = nil;
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:@"Choose where to save"];
    [sp setNameFieldStringValue:_name];
    
    if ([sp runModal] != NSModalResponseOK)
        return;
    
    path = sp.URL.path;
    
    // XXX
    /*
     * Does this location belong to our `searchPaths`?
     */
    MCSettings *mcsettings = [MCSettings sharedInstance];
    if (
        ![[mcsettings additionalSearchPaths] containsObject:path] &&
        ![[mcsettings configsLocation] isEqualToString:path])
    {
        /* prompt user to add this to search paths */
        NSAlert *addSearchPath = [[NSAlert alloc] init];
        [addSearchPath setMessageText:@"Would you like to add this location to your search paths?"];
        [addSearchPath setAlertStyle:NSAlertStyleCritical];
        [addSearchPath addButtonWithTitle:@"Yes"];
        [addSearchPath addButtonWithTitle:@"No"];

        if ([addSearchPath runModal] == NSAlertFirstButtonReturn)
            [mcsettings addAdditionalSearchPath:path.stringByDeletingLastPathComponent];
        
        NSLog(@"Additional Search Locations: %@", [mcsettings additionalSearchPaths]);
    }
    
    /*
     * Create Theme directory
     */
    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
    {
        NSLog(@"saveTheme: %@", error);
        return;
    }
    
    /*
     * Create ThemeRC
     */
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

    /* copy wallpaper */
    if (_relative)
    {
        [[NSFileManager defaultManager] copyItemAtPath:_wallpaper toPath:[path stringByAppendingPathComponent:_wallpaper.lastPathComponent] error:&error];
        if (error)
            NSLog(@"%@", error);
    }
    
    error = nil;
    
    /*
     * copy preview image and set its name to <widgetName>.jpg
     */
    [[NSFileManager defaultManager] copyItemAtPath:_preview toPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", path.lastPathComponent]] error:&error];
    if (error)
        NSLog(@"%@", error);
    
    /* open theme directory */
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
    
    /* refresh List of Widgets/Themes */
    [[[MCSettings sharedInstance] mainViewController] updateWidgetsThemesArray];
}

//
// DATA SOURCE =====================================================================================
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
