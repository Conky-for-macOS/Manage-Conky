//
//  ViewController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ViewController.h"

#import "Shared.h"
#import "Logger.h"
#import "MCConfigEditor.h"  // Editor View Controller
#import "AboutSheetController.h"
#import "ConkyThemesSheetController.h"
#import "ConkyPreferencesSheetController.h"
#import "Extensions/StringScore/NSString+Score.h"

#define MC_DO_NOT_LOG   nil
#define ERR_NSFD        260 /* no such file or directory */

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     * Setup stuff
     */
    NSString *kConkyConfigsDefaultPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Conky"];
    NSString *kDefaultLogfile = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/ManageConky.log"];

    /*
     * Will happen for every ViewController we allocate;
     * BUT, inside MCSettings we have a GUARD that returns
     * if the method has been called already once; THUS,
     * we only get the handle of the mainViewController,
     * which is actually really useful for many stuff...
     */
    [[MCSettings sharedSettings] setMainViewController:self];
    
    whatToShow = widgetsThemesTableShowWidgets; /* initial value */
    
    /*
     * Logging
     * =======
     */
    shouldLogToFile = [[MCSettings sharedSettings] shouldLogToFile];
    NSString *lf = [[MCSettings sharedSettings] logfile];
    
    /*
     * Check if logging is enabled; If yes, check if we want default logfile (length = 0)
     *                              or, we want user-defined (length > 0)
     * Otherwise, set logfile to nil.  (We interpret it as DO_NOT_LOG)
     */
    if (shouldLogToFile)
        logfile = (lf && lf.length > 0) ? lf : kDefaultLogfile;
    else
        logfile = MC_DO_NOT_LOG;

    /*
     * Setup Default ConkyConfigs Location
     */
    if (![[MCSettings sharedSettings] configsLocation]
        || [[[MCSettings sharedSettings] configsLocation] isEqualToString:@""])
    {
        [[MCSettings sharedSettings] setConfigsLocation:kConkyConfigsDefaultPath];
    }

    [self fillWidgetsThemesArrays];
}

//
// DATA ARRAYS CONTROL
//

- (NSMutableArray *)widgets { return widgetsArray; }
- (NSMutableArray *)themes { return themesArray; }
- (void)createWidgetsArray  { widgetsArray = [NSMutableArray array]; }

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
        MCError(&error, @"fill");
        return nil;
    }
    
    return [mcignoreItems componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

- (void)fillWidgetsThemesArraysWithSearchPath:(NSString *)searchPath
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *basicSearchDirectoryContents = [fm contentsOfDirectoryAtPath:searchPath error:&error];
    if (!basicSearchDirectoryContents)
    {
        MCError(&error, @"Error: Failed getting list contents of %@", searchPath);
        return;
    }
    
    /*
     * Foreach item in the basic-search-path get enumerator of contents.
     */
    for (NSString *item in basicSearchDirectoryContents)
    {
        NSString *itemFullpath = [searchPath stringByAppendingPathComponent:item];   /* full path for item of basicSearchDirectory */
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
                    MCWidget *widget = [MCWidget widgetWithPid:MC_PID_NOT_SET andRC:widgetRCFullpath];
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
    
    NSString *basicSearchPath = [[MCSettings sharedSettings] configsLocation];
    NSArray *additionalSearchPaths = [[MCSettings sharedSettings] additionalSearchPaths];
    
    if (!basicSearchPath)
    {
        NSLog(@"Error: no basicSearchPath set!");
        return;
    }
    
    if (!additionalSearchPaths)
    {
        NSLog(@"No additional search paths set!");
    }
    
    /* fill arrays for basic-search-path */
    [self fillWidgetsThemesArraysWithSearchPath:basicSearchPath];
    
    /* fill arrays for each additional-search-path */
    if (!additionalSearchPaths)
        return;
    for (NSString *additionalSearchPath in additionalSearchPaths)
        [self fillWidgetsThemesArraysWithSearchPath:additionalSearchPath];
}

- (void)updateWidgetsThemesArray
{
    [self emptyWidgetsThemesArrays];
    [self fillWidgetsThemesArrays];
    [_widgetsThemesTable reloadData];
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
     * For conky-manager all preview files all jpeg and follow the naming: <widgetName>.jpg
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
    [previewPopover showRelativeToRect:[[NSApp mainWindow] contentView].bounds
                                ofView:[[NSApp mainWindow] contentView]
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
        str = [[[arr objectAtIndex:row] themeRC] stringByDeletingLastPathComponent];
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
        BOOL usesAbsolutePaths = [[MCSettings sharedSettings] usesAbsolutePaths];
        NSTextFieldCell *cell = [tableColumn dataCellForRow:row];
        
        /*
         * check if already allocated
         */
        if (!cell)
            cell = [[NSTextFieldCell alloc] init];
        
        cell.stringValue = (usesAbsolutePaths) ? [str stringByDeletingPathExtension] : [[str lastPathComponent] stringByDeletingPathExtension];
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
        
        /* Do we need the Logger? */
        if ([_toggleLoggerButton state])
        {
//            NSLog(@"I am enabling logging for %@", widget.realName);
            
            Logger *logger = [[Logger alloc] initWithWindowNibName:@"Logger" andMode:GSC_MODE_WINDOW];
            [logger setWidgetName:widget.realName];
            [logger loadOnWindow:[NSApp mainWindow]];
        }
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
        MCError(&error, @"ignore: error");
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
        MCError(&error, @"ignore: error");

    [self updateWidgetsThemesArray];
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
    
    NSURL *url = [NSURL fileURLWithPath:CONKYX];
    if (!url)
        return;

    NSError *error = nil;
    NSArray *arguments = @[@"-c",
                           [widget itemPath],
                           ];
    
    [[NSWorkspace sharedWorkspace] launchApplicationAtURL:url
                                                  options:0
                                            configuration:[NSDictionary dictionaryWithObject:arguments forKey:NSWorkspaceLaunchConfigurationArguments]
                                                    error:&error];

    if (error)
        MCError(&error);
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

- (IBAction)toggleLogger:(id)sender
{
    [_toggleLoggerButton setImage:([sender state] ? [NSImage imageNamed:NSImageNameStatusAvailable] : nil)];
}

@end
