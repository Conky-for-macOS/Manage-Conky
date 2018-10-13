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
            [fromListWidgets addObject:widget.realName];
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

// HELPER
- (NSMutableArray *)getConkyConfigsFrom:(NSMutableArray *)widgetsFromList and:(NSMutableArray *)widgetsFromDirectories
{
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObjectsFromArray:widgetsFromList];
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

    if (_name.empty || _source.empty || _creator.empty || !_conkyConfigs || ([_conkyConfigs count] == 0))
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
    
    NSModalResponse res = [approveWidgets runModal];
    if (res == NSAlertFirstButtonReturn)
        return;

    /*
     * User wants to continue; Create the Theme
     */
    NSString *basicSearchPath = [[MCSettings sharedInstance] configsLocation];
    NSString *path = [basicSearchPath stringByAppendingPathComponent:_name];
    
    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];
    
    /* Create theme directory */
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];

    if (error)
    {
        NSLog(@"saveTheme: %@", error);
        return;
    }

    /* Set dictionary */
    if (_relative) [themerc setObject:_wallpaper.lastPathComponent forKey:@"wallpaper"];
    else [themerc setObject:_wallpaper forKey:@"wallpaper"];

    [themerc setObject:_conkyConfigs forKey:@"conkyConfigs"];
    [themerc setObject:_source forKey:@"source"];
    [themerc setObject:_creator forKey:@"creator"];
    [themerc setObject:[NSString stringWithUTF8String:cMacScalingKeys[_scaling]] forKey:@"scaling"];

    /* Write dictionary */
    [themerc writeToFile:[path stringByAppendingPathComponent:@"themerc.plist"]
              atomically:YES];

    error = nil;    // re-use

    /* Set Resources */
    if (_relative)
    {
        [[NSFileManager defaultManager] copyItemAtPath:_wallpaper toPath:[path stringByAppendingPathComponent:_wallpaper.lastPathComponent] error:&error];

        if (error)
            NSLog(@"saveTheme: %@", error);
    }
}

- (IBAction)chooseWallpaper:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseDirectories = NO;
    panel.allowedFileTypes = @[@"png", @"jpg", @"tiff"];
    
    /*
     * display the panel
     */
    NSModalResponse result = [panel runModal];
    
    if (result == NSModalResponseOK)
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
    
    alert.informativeText = @"Path relative or Full?";
    alert.messageText = @"Choosing a relative path will tell ManageConky to save the wallpaper inside your theme directory! This way you have a portable Theme!";
    [alert addButtonWithTitle:@"Relative"];
    [alert addButtonWithTitle:@"Fullpath"];
    
    NSModalResponse response = [alert runModal];
    
    switch (response)
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
        
        NSModalResponse res = [op runModal];
        
        if (res == NSModalResponseOK)
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

//
// DATA SOURCE
//

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (selectedView == MC_FROM_LIST) ? [fromListWidgets count] : [fromDirectoryWidgets count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0)
        return nil;

    if ([[tableColumn identifier] isEqualToString:@"Text"])
    {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Text" owner:nil];
        [[cell textField] setStringValue:(selectedView == MC_FROM_LIST) ? [fromListWidgets objectAtIndex:row] : [fromDirectoryWidgets objectAtIndex:row]];
        return cell;
    }
    else if ([[tableColumn identifier] isEqualToString:@"Checkbox"])
    {
        if (selectedView == MC_FROM_LIST)
        {
            
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Checkbox" owner:nil];
            
            return cell;
        }
    }
    
    return nil;
}

@end
