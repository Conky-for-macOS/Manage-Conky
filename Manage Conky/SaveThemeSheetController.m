//
//  SaveThemeSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "SaveThemeSheetController.h"

#import "ViewController.h"
#import <Fragaria/Fragaria.h>
#import "MCObjects/MCObjects.h"
#import "SaveThemeSheetCheckbox.h"
#import "SaveWidgetSheetController.h"
#import "Extensions/NSString+Empty.h"
#import "Extensions/NSAlert+runModalSheet.h"

enum {
    MC_FROM_LIST = 0,
    MC_FROM_DIRECTORY,
    
    MC_FROM_XXX_COUNT   /* serves as a count of enum entries */
};

/*
 * Registry of checkboxes
 */
static NSMutableArray<Checkbox *> *checkboxRegistry[MC_FROM_XXX_COUNT];
static NSUInteger fromListWidgetsCount = 0;         /* the -fromList- widgets */
static NSUInteger fromDirectoryWidgetsCount = 0;    /* the -fromDirectory- widgets */
static NSUInteger selectedView;

/*
 * Registry of Checkboxes Manipulation Functions
 */
void checkbox_registry_uncheck_all(void)
{
    for (int i = 0; i < checkboxRegistry[MC_FROM_LIST].count; i++)
        checkboxRegistry[MC_FROM_LIST][i].state = NSOffState;
    
    for (int i = 0; i < checkboxRegistry[MC_FROM_DIRECTORY].count; i++)
        checkboxRegistry[MC_FROM_DIRECTORY][i].state = NSOffState;
}

//
//=================================================================================
//

@implementation Checkbox
+ (instancetype)checkboxForWidgetWithIdentifier:(NSString *)widgetIdentifier
{
//    NSLog(@"Getting chkbx for view: %d", selectedView);
    
    NSUInteger count = (selectedView == MC_FROM_LIST) ? fromListWidgetsCount : fromDirectoryWidgetsCount;
    
    /* check if registry has already been created */
    if (checkboxRegistry[selectedView])
    {
        /* Try to find an entry corresponding to this widget! */
        for (Checkbox *cb in checkboxRegistry[selectedView])
            if ([[cb widgetID] isEqualToString:widgetIdentifier])
                return cb;  /* return one from registry */
    }
    else
        checkboxRegistry[selectedView] = [NSMutableArray arrayWithCapacity:count];
    
    /*
     * either registry hadn't been created yet
     * or we didn't find an entry; create one.
     */
    id entry = [[Checkbox alloc] init];
    if (entry)
    {
        [entry setWidgetID:widgetIdentifier];
        
        /* publish ourselves to registry */
        [checkboxRegistry[selectedView] addObject:entry];
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
    
    checkboxRegistry[selectedView][row].state = [(NSButton *)sender state];
}
@end

@implementation SaveThemeSheetController

- (void)basicInitialisation
{
    /*
     * Basic initialisation
     */
    _scaling = FillScreen;
    _relative = YES;
    
    _conkyConfigs = [NSMutableArray array];
    _conkyConfigsPaths = [NSMutableArray array];
    fromListWidgets = [NSMutableArray array];
    fromDirectoryWidgets = [NSMutableArray array];
    searchDirectories = [NSMutableArray array];
    
    [self populateFromListWidgetsArray];
    
    [_widgetsTableView setDelegate:self];
    [_widgetsTableView setDataSource:self];
    
    checkboxRegistry[0] = nil;
    checkboxRegistry[1] = nil;
    
    selectedView = MC_FROM_LIST;
}

- (id)initWithWindowNibName:(NSString *)nibName
{
    self = [super initWithWindowNibName:nibName];
    if (self) { [self basicInitialisation]; }
    return self;
}

- (id)initWithWindowNibName:(NSString *)nibName andMode:(NSUInteger)mode
{
    /* we implement a custom init function, this DOES it! */
    self = [super initWithWindowNibName:nibName andMode:mode];
    if (self)
    {
        [self basicInitialisation];
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

/*
 * FromListWidgets Array Manipulation
 */
- (void)populateFromListWidgetsArray
{
    /*
     * Our ViewController already contains the infrastructure
     * for getting the list of widgets in a directory; Use it
     * to speed things up.
     */
    ViewController *vc = [[ViewController alloc] init];
    [vc fillWidgetsThemesArrays];
    
    for (MCWidget *widget in vc.widgets)
    {
        [fromListWidgets addObject:widget.widgetRC];
    }
    
    [_widgetsTableView reloadData];
}
- (void)re_populateFromListWidgetsArray
{
    [fromListWidgets removeAllObjects];
    [self populateFromListWidgetsArray];
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
        _wallpaper = panel.URL.path;
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
        _preview = panel.URL.path;
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
                [fromDirectoryWidgets addObject:widget.widgetRC];
        }
    }
    
    selectedView = [sender selectedSegment];

    [_widgetsTableView reloadData];
}

- (IBAction)clear:(id)sender
{
}

//
//=========================================================================================================
//

- (void)didSaveWidget
{
    [self re_populateFromListWidgetsArray];
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
    for (Checkbox *cb in checkboxRegistry[MC_FROM_LIST])
        if ([fromListWidgets doesContain:[cb widgetID]] && ([cb state] == NSOnState))
            [arr addObject:[cb widgetID]];
    
    for (Checkbox *cb in checkboxRegistry[MC_FROM_DIRECTORY])
        if ([fromDirectoryWidgets doesContain:[cb widgetID]] && ([cb state] == NSOnState))
            [arr addObject:[cb widgetID]];
    
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
    _conkyConfigsPaths = [self getConkyConfigsFrom:fromListWidgets and:fromDirectoryWidgets];
    
    for (NSString *config in _conkyConfigsPaths)
    {
        [_conkyConfigs addObject:config.lastPathComponent];
    }
    
    if (_name.empty || _source.empty || _creator.empty || !_wallpaper || !_conkyConfigsPaths || ([_conkyConfigsPaths count] == 0))
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Whoah! Hold your horses!"];
        [alert setInformativeText:@"You forgot to fill in some info."];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModalSheetForWindow:self.window];
        return;
    }
    
    /* get PROPER rect for our text */
    NSTextField *dummyField = [NSTextField textFieldWithString:[_conkyConfigsPaths componentsJoinedByString:@"\n"]];
    NSRect editorFieldRect = dummyField.bounds;
    
    /* create fragaria view */
    MGSFragariaView *mgs = [[MGSFragariaView alloc] initWithFrame:editorFieldRect];
    [mgs setString:[_conkyConfigsPaths componentsJoinedByString:@"\n"]];
    [mgs setShowsLineNumbers:NO];

    /* prompt user whether to continue or not */
    NSAlert *approveWidgets = [[NSAlert alloc] init];
    [approveWidgets setMessageText:@"You want these Widgets in your Theme?"];
    [approveWidgets setInformativeText:@"Summary:"];
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
    NSString *parentDirectory = nil;
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:@"Choose where to save"];
    [sp setNameFieldStringValue:_name];
    
    if ([sp runModal] != NSModalResponseOK)
        return;
    
    path = sp.URL.path;
    parentDirectory = [path stringByDeletingLastPathComponent];
    
    /*
     * Does this location belong to our `searchPaths`?
     */
    MCSettings *mcsettings = [MCSettings sharedSettings];
    if (
        ![[mcsettings additionalSearchPaths] containsObject:parentDirectory] &&
        ![[mcsettings configsLocation] isEqualToString:parentDirectory])
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
    NSError *error = nil;
    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        MCError(&error, @"saveTheme");
        return;
    }
    
    /*
     * Create ThemeRC
     */
    if (_relative) [themerc setObject:_wallpaper.lastPathComponent forKey:kMCThemeWallpaperKey];
    else [themerc setObject:_wallpaper forKey:kMCThemeWallpaperKey];
    
    [themerc setObject:_conkyConfigs forKey:kMCThemeConfigsKey];
    [themerc setObject:_source forKey:kMCThemeSourceKey];
    [themerc setObject:_creator forKey:kMCThemeCreatorKey];
    [themerc setObject:[NSString stringWithUTF8String:cMacScalingKeys[_scaling]] forKey:kMCThemeScalingKey];
    
    /* Write ThemeRC */
    [themerc writeToFile:[path stringByAppendingPathComponent:@"themerc.plist"]
              atomically:YES];

    /*
     * Copy Resources
     */
    /* copy widgets */
    for (NSString *widgetPath in _conkyConfigsPaths)
        if (![[NSFileManager defaultManager] copyItemAtPath:widgetPath toPath:[path stringByAppendingPathComponent:widgetPath.lastPathComponent] error:&error])
            MCError(&error);

    /* copy wallpaper */
    if (_relative)
        if (![[NSFileManager defaultManager] copyItemAtPath:_wallpaper toPath:[path stringByAppendingPathComponent:_wallpaper.lastPathComponent] error:&error])
            MCError(&error);

    /*
     * copy preview image and set its name to <widgetName>.jpg
     */
    if (![[NSFileManager defaultManager] copyItemAtPath:_preview toPath:[path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", path.lastPathComponent]] error:&error])
        MCError(&error);

    /* open theme directory */
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path]];
    
    /* refresh List of Widgets/Themes */
    [[[MCSettings sharedSettings] mainViewController] updateWidgetsThemesArray];
}

//
// DATA SOURCE =====================================================================================
//

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    fromListWidgetsCount = [fromListWidgets count];
    fromDirectoryWidgetsCount = [fromDirectoryWidgets count];
    return (selectedView == MC_FROM_LIST) ? [fromListWidgets count] : [fromDirectoryWidgets count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0)
        return nil;

    if ([[tableColumn identifier] isEqualToString:@"Text"])
    {
        NSString *str = (selectedView == MC_FROM_LIST) ? [[fromListWidgets objectAtIndex:row] lastPathComponent] : [fromDirectoryWidgets objectAtIndex:row];
        
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Text" owner:nil];
        [[cell textField] setStringValue:str];
        return cell;
    }
    else if ([[tableColumn identifier] isEqualToString:@"Checkbox"])
    {
        NSString *str = (selectedView == MC_FROM_LIST) ? [fromListWidgets objectAtIndex:row] : [fromDirectoryWidgets objectAtIndex:row];
        
        Checkbox *cb = [Checkbox checkboxForWidgetWithIdentifier:str];
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Checkbox" owner:cb];
        return cell;
    }
    
    return nil;
}

@end
