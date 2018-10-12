//
//  ViewController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ViewController.h"

#import "Shared.h"
#import "MCConfigEditor.h"  // Editor View Controller
#import "Extensions/StringScore/NSString+Score.h"

#import "ConkyPreferencesSheetController.h"
#import "ConkyThemesSheetController.h"
#import "AboutSheetController.h"

#define ERR_NSFD 260    /* no such file or directory */

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*
     * Setup stuff
     */
    
    /*
     * Logging
     * =======
     */
    NSNumber *loggingEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"Logging"];
    shouldLogToFile = loggingEnabled.boolValue;
    NSString *lf = [[NSUserDefaults standardUserDefaults] objectForKey:@"LogfileLocation"];
    
    /*
     * Check if logging is enabled; If yes, check if we want default logfile (length = 0)
     *                              or, we want user-defined (length > 0)
     * Otherwise, set logfile to nil.  (We interpret it as DO_NOT_LOG)
     */
#define MC_DO_NOT_LOG nil
    if (shouldLogToFile)
        logfile = (lf && lf.length > 0) ? lf : @"/Library/Logs/ManageConky.log";
    else
        logfile = MC_DO_NOT_LOG;
    
    /* Is conky set to run at startup? */
    BOOL a = [[[NSUserDefaults standardUserDefaults] objectForKey:@"runConkyAtStartup"] boolValue];
    
    /* publish it to our settings-holder */
    MCSettingsHolder = [MCSettings sharedInstance];
    [MCSettingsHolder setConkyRunsAtStartup:a];
    
    whatToShow = widgetsThemesTableShowWidgets; /* initial value */
    
    /* Conky configuration file location? */
    NSString *conkyConfigsPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    if (!conkyConfigsPath || [conkyConfigsPath isEqualToString:@""])
    {
        NSString *kConkyConfigsDefaultPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Conky"];    /* default value */
        
        [[NSUserDefaults standardUserDefaults] setObject:kConkyConfigsDefaultPath forKey:@"configsLocation"];
        conkyConfigsPath = kConkyConfigsDefaultPath;
    }

    [self fillWidgetsThemesArrays];
}

//
// DATA ARRAYS CONTROL
//

- (void)emptyWidgetsThemesArrays
{
    [widgetsArray removeAllObjects];
    [themesArray removeAllObjects];
}

- (NSArray *)getExcludedFromPath:(NSString *)path
{
    NSError *error = nil;
    NSString *mcignore = [path stringByAppendingPathComponent:@".mcignore"];
    NSString *mcignoreItems = [[NSString alloc] initWithContentsOfFile:mcignore
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
    
    if (error && error.code != ERR_NSFD)
    {
        NSLog(@"fill: %@", error);
        return nil;
    }
    
    return [mcignoreItems componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)fillWidgetsThemesArraysWithBasicSearchPath:(NSString *)basicSearchPath
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *basicSearchDirectoryContents = [fm contentsOfDirectoryAtPath:basicSearchPath error:&error];
    if (!basicSearchDirectoryContents)
    {
        NSLog(@"Error: Failed getting list of %@ contents: \n\n%@", basicSearchPath, error);
        return;
    }
    
    /*
     * Foreach item in the basic-search-path get enumerator of contents.
     */
    for (NSString *item in basicSearchDirectoryContents)
    {
        NSString *itemFullpath = [basicSearchPath stringByAppendingPathComponent:item];   /* full path for item of basicSearchDirectory */
        NSMutableArray *itemContents = [fm contentsOfDirectoryAtPath:itemFullpath error:&error].mutableCopy;   /* list of sub-items in item */
        
        if (!itemContents)
            continue;
        
        /* Exclude all stuff in .mcignore */
        [itemContents removeObjectsInArray:[self getExcludedFromPath:itemFullpath]];
        
        /*
         * This variable is set only if the following loop fails to locate
         *  Theme but does locate Widget.
         */
        BOOL foundWidget = NO;
        
        for (NSString *subItem in itemContents)
        {
            if ([[subItem pathExtension] isEqualToString:@"cmtheme"] || [subItem isEqualToString:@"themerc.plist"])
            {
                BOOL useNewThemeRCFormat = [subItem isEqualToString:@"themerc.plist"] ? YES : NO;
                NSString *themeRC = [itemFullpath stringByAppendingPathComponent:(useNewThemeRCFormat ? @"themerc.plist" : subItem)];
                
                MCTheme *theme = [MCTheme themeRepresentationForThemeRC:themeRC];
                [themesArray addObject:theme];
                
                /*
                 * Break and set foundWidget to NO to avoid treating item as Widget;
                 * Remember: Themes should be first priority.
                 */
                foundWidget = NO;
                break;
            }
            else
            {
                if ([subItem isEqualToString:@".DS_Store"])
                    continue;
                
                if ([subItem isEqualToString:@".mcignore"])
                    continue;
                
                /*
                 * subItem definitely isn't a Theme but it could be a Widget.
                 * Check if it really is and set the appropriate variables.
                 */
                if ([[subItem pathExtension] isEqualToString:@""])
                {
                    foundWidget = YES;
                }
            }
        }
        
        if (foundWidget)
        {
            /*
             * Re-iterate in item to add all conky configs to array.
             */
            
            for (NSString *subItem in itemContents)
            {
                if ([subItem isEqualToString:@".DS_Store"])
                    continue;
                
                if ([subItem isEqualToString:@".mcignore"])
                    continue;
                
                /*
                 * subItem definitely isn't a Theme but it could be a Widget.
                 * Check if it really is and set the appropriate variables.
                 */
                if ([[subItem pathExtension] isEqualToString:@""])
                {
                    NSString *widgetRCFullpath = [itemFullpath stringByAppendingPathComponent:subItem];
                    MCWidget *widget = [MCWidget widgetWithPid:MC_PID_NOT_SET andPath:widgetRCFullpath];
                    [widgetsArray addObject:widget];
                }
            }
        }
    }
}

- (void)fillWidgetsThemesArrays
{
    widgetsArray = [NSMutableArray array];
    themesArray = [NSMutableArray array];
    
    NSString *basicSearchPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    NSArray *additionalSearchPaths = [[NSUserDefaults standardUserDefaults] objectForKey:@"additionalSearchPaths"];
    
    if (!basicSearchPath)
    {
        NSLog(@"Error: no basicSearchPath set!");
        return;
    }
    
    /* fill arrays for basic-search-path */
    [self fillWidgetsThemesArraysWithBasicSearchPath:basicSearchPath];
    
    /* fill arrays for each additional-search-path */
    if (!additionalSearchPaths)
        return;
    for (NSString *additionalSearchPath in additionalSearchPaths)
        [self fillWidgetsThemesArraysWithBasicSearchPath:additionalSearchPath];
}

//
// TABLE CONTROL
//

/**
 * Change to themes list or widgets list
 **/
- (IBAction)changeTableContents:(id)sender
{
    if ([[sender title] isEqualToString:@"Themes"])
        whatToShow = widgetsThemesTableShowThemes;
    if ([[sender title] isEqualToString:@"Widgets"])
        whatToShow = widgetsThemesTableShowWidgets;
    
    [_widgetsThemesTable reloadData];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;

    /*
     * For conky-manager all preview files all jpeg and follow the naming: widgetName.jpg
     */
    NSString *preview = nil;
    
    /*
     *  If user selected a widget show preview.
     */
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        MCWidget *widget = [widgetsArray objectAtIndex:row];
        preview = [[widget itemPath] stringByAppendingPathExtension:@"jpg"];
    }
    else if (whatToShow == widgetsThemesTableShowThemes)
    {
        MCTheme *theme = [themesArray objectAtIndex:row];
        NSString *themeRoot = [[theme themeRC] stringByDeletingLastPathComponent];
        NSString *themeName = [themeRoot lastPathComponent];
        preview = [[themeRoot stringByAppendingPathComponent:themeName] stringByAppendingPathExtension:@"jpg"];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:preview];
    
    if (!image)
        return;
    
    CGFloat w = [image size].width;
    CGFloat h = [image size].height;
    
    /*
     * Resize image if too big!
     */
    if (h > 800 || w > 400)
        [image setSize:NSMakeSize(w/1.5, h/1.5)];
    
    NSImageView *imageView = [NSImageView imageViewWithImage:image];
    [imageView setImageScaling:NSImageScaleNone];
    
    NSViewController *controller = [[NSViewController alloc] init];
    [controller setView:imageView];
    
    if (!previewPopover)
    {
        previewPopover = [[NSPopover alloc] init];
        [previewPopover setBehavior:NSPopoverBehaviorSemitransient];
        [previewPopover setAnimates:YES];
    }
    
    /*
     * close any previously created popover
     */
    [previewPopover setAnimates:NO];  /* close without animation */
    [previewPopover close];
    [previewPopover setAnimates:YES]; /* show with animation */
    
    /*
     * setup a new popover preview
     */
    [previewPopover setContentViewController:controller];
    [previewPopover setContentSize:[image size]];
    
    /*
     * show the preview
     */
    [previewPopover showRelativeToRect:[[notification object] bounds]
                                ofView:[notification object]
                         preferredEdge:NSMaxXEdge];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (whatToShow == widgetsThemesTableShowWidgets) ? [widgetsArray count] : [themesArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSArray *arr = nil;
    NSString *str = nil;
    
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        arr = widgetsArray;
        str = [[arr objectAtIndex:row] itemPath];
    }
    else
    {
        arr = themesArray;
        str = [[arr objectAtIndex:row] themeName];
    }
    
    if ([[tableColumn identifier] isEqualToString:@"CollumnA"])
    {
        BOOL isEnabled = [[arr objectAtIndex:row] isEnabled];
        
        NSImage *cell = [tableColumn dataCellForRow:row];
        
        /*
         * check if already allocated
         */
        if (!cell)
            cell = [[NSImage alloc] init];
        
        cell = isEnabled ? [NSImage imageNamed:@"noun_enabled_896264_3BB300"] : [NSImage imageNamed:@"noun_disabled_1467765_FF6868"];
        return cell;
    }
    else
    {
        NSTextFieldCell *cell = [tableColumn dataCellForRow:row];
        
        /*
         * check if already allocated
         */
        if (!cell)
            cell = [[NSTextFieldCell alloc] init];
        
        cell.stringValue = str;
        return cell;
    }
}

//
// CONKY CONTROL
//
- (IBAction)startOrRestartWidget:(id)sender
{
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;
    
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        MCWidget *widget = [widgetsArray objectAtIndex:row];
        
        if ([widget isEnabled]) [widget reenable];
        else [widget enable];
    }
    else
    {
        MCTheme *theme = [themesArray objectAtIndex:row];
        [theme reenable];
    }
    
    [_widgetsThemesTable reloadData];
}
- (IBAction)stopWidget:(id)sender
{
    NSInteger i = [_widgetsThemesTable selectedRow];
    
    if (i < 0)
        return;
    
    if (whatToShow == widgetsThemesTableShowThemes)
    {
        MCTheme *theme = [themesArray objectAtIndex:i];
        if ([theme isEnabled])
            [theme disable];
    }
    else
    {
        MCWidget *widget = [widgetsArray objectAtIndex:i];
        if ([widget isEnabled])
            [widget disable];
    }
    
    [_widgetsThemesTable reloadData];
}
- (IBAction)stopAllWidgets:(id)sender
{
    if (whatToShow == widgetsThemesTableShowThemes)
    {
        for (MCTheme *theme in themesArray)
            if ([theme isEnabled])
                [theme disable];
    }
    else
    {
        for (MCWidget *widget in widgetsArray)
        {
            if ([widget isEnabled])
                [widget disable];
        }
    }
    
    [_widgetsThemesTable reloadData];
}

- (IBAction)edit:(id)sender
{
    /* guard */
    if (whatToShow != widgetsThemesTableShowWidgets)
        return;
    
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;
    
    MCWidget *widget = [widgetsArray objectAtIndex:row];

    /*
     * Initialise editor controller
     */
    MCConfigEditor *editorController = [[MCConfigEditor alloc] initWithConfig:[widget itemPath]];

    /*
     * Initialise editor popover
     */
    if (!editorPopover)
    {
        editorPopover = [[NSPopover alloc] init];
        [editorPopover setBehavior:NSPopoverBehaviorSemitransient];
        [editorPopover setAnimates:YES];
    }
    
    /*
     * Setup a new popover
     */
    [editorPopover setContentViewController:editorController];
    [editorPopover setContentSize:[editorController editorField].bounds.size];

    /*
     * Show popover
     */
    [editorPopover showRelativeToRect:[sender bounds]
                               ofView:sender
                        preferredEdge:NSMaxXEdge];
}

- (IBAction)ignore:(id)sender
{
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;
    
    NSString *mcignore = @"";
    NSString *itemPath = @"";
    NSString *itemName = @"";
    
    NSError *error = nil;
    
    switch (whatToShow)
    {
        case widgetsThemesTableShowWidgets:
            itemPath = [[widgetsArray objectAtIndex:row] itemPath];
            break;
        case widgetsThemesTableShowThemes:
            itemPath = [[themesArray objectAtIndex:row] themeRC];
            break;
    }
    
    mcignore = [[itemPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".mcignore"];
    
    /*
     * Try to initialise with contents of .mcignore
     */
    itemName = [[NSString alloc] initWithContentsOfFile:mcignore
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    
    if (error && error.code != ERR_NSFD)
    {
        NSLog(@"ignore: error %@", error);
        return;
    }
    
    if (!itemName)
    {
        itemName = [[itemPath lastPathComponent] stringByAppendingString:@"\n"];
    }
    else
    {
        itemName = [itemName stringByAppendingFormat:@"%@\n", [itemPath lastPathComponent]];
    }
    
    error = nil;
    
    /*
     * Write to .mcignore
     */
    [itemName writeToFile:mcignore
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:&error];
    
    if (error)
        NSLog(@"ignore: %@", error);

    [self emptyWidgetsThemesArrays];
    [self fillWidgetsThemesArrays];
    [_widgetsThemesTable reloadData];
}

- (IBAction)openInFinder:(id)sender
{
    NSInteger row = [_widgetsThemesTable selectedRow];
    NSString *containingDirectory = nil;
    
    if (row < 0)
        return;
    
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        MCWidget *widget = [widgetsArray objectAtIndex:row];
        containingDirectory = [[widget itemPath] stringByDeletingLastPathComponent];
    }
    else if (whatToShow == widgetsThemesTableShowThemes)
    {
        MCTheme *theme = [themesArray objectAtIndex:row];
        containingDirectory = [[theme themeRC] stringByDeletingLastPathComponent];
    }
    
    [[NSWorkspace sharedWorkspace] openFile:containingDirectory];
}

- (IBAction)uninstall:(id)sender
{
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;
    
    id obj = (whatToShow == widgetsThemesTableShowWidgets) ? [widgetsArray objectAtIndex:row] : [themesArray objectAtIndex:row];
    [obj uninstall];
    
    [self emptyWidgetsThemesArrays];
    [self fillWidgetsThemesArrays];
    [_widgetsThemesTable reloadData];
}

- (IBAction)runCommand:(id)sender
{
    if (whatToShow != widgetsThemesTableShowWidgets)
        return;
    
    NSInteger row = [_widgetsThemesTable selectedRow];
    
    if (row < 0)
        return;
    
    MCWidget *widget = [widgetsArray objectAtIndex:row];

    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];

    NSURL *url = [NSURL fileURLWithPath:CONKYX];

    if (!url)
        return;

    NSError *error = nil;
    NSArray *arguments = @[@"-c",
                           [widget itemPath],
                           ];
    
    [workspace launchApplicationAtURL:url
                              options:0
                        configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments]
                                error:&error];

    if (error)
        NSLog(@"%@", error);
}

//
// SearchField Control
//

- (void)searchFieldDidStartSearching:(NSSearchField *)sender
{
    NSString *txt = [sender stringValue];

    NSMutableArray *searchArray = [[NSMutableArray alloc] init];
    NSMutableArray *objectArray = (whatToShow == widgetsThemesTableShowWidgets) ? (NSMutableArray *)widgetsArray : (NSMutableArray *)themesArray;

    CGFloat score = 0;

    for (id object in objectArray)
    {
        score = [txt scoreAgainst:[object realName]
                        fuzziness:[NSNumber numberWithInteger:0.8]
                          options:(NSStringScoreOptionFavorSmallerWords | NSStringScoreOptionReducedLongStringPenalty)];
        
        if (score >= 0.5)
            [searchArray addObject:object];
    }
    
    [objectArray removeAllObjects];
    [objectArray addObjectsFromArray:searchArray];
    
    [_widgetsThemesTable reloadData];
}

- (void)searchFieldDidEndSearching:(NSSearchField *)sender
{
    [self fillWidgetsThemesArrays];
    [_widgetsThemesTable reloadData];
}

- (IBAction)loadConkyPreferences:(id)sender
{
    ConkyPreferencesSheetController *pfctl = [[ConkyPreferencesSheetController alloc] initWithWindowNibName:@"ConkyPreferences"];
    [pfctl loadOnWindow:[NSApp mainWindow]];
    [pfctl initStuff];
}
- (IBAction)loadConkyThemes:(id)sender
{
    [[[ConkyThemesSheetController alloc] initWithWindowNibName:@"ConkyThemes"] loadOnWindow:[NSApp mainWindow]];
}
- (IBAction)loadAbout:(id)sender
{
    [[[AboutSheetController alloc] initWithWindowNibName:@"About"] loadOnWindow:[NSApp mainWindow]];
}

@end
