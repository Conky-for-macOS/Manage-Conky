//
//  ViewController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ViewController.h"
#import "MCConfigEditor.h"  // Editor View Controller


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     * Setup stuff
     */
    
    /* Is conky set to run at startup? */
    BOOL a = [[[NSUserDefaults standardUserDefaults] objectForKey:@"runConkyAtStartup"] boolValue];
    
    /* publish it to our settings-holder */
    MCSettingsHolder = [[MCSettings alloc] init];
    [MCSettingsHolder setConkyRunsAtStartup:a];
    
    whatToShow = widgetsThemesTableShowWidgets; /* initial value */
    
    [self fillWidgetsThemesArrays];
    
    [_widgetsThemesTable setDelegate:self];
    [_widgetsThemesTable setDataSource:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

//
// DATA ARRAYS CONTROL
//

- (void)emptyWidgetsThemesArrays
{
    [widgetsArray removeAllObjects];
    [themesArray removeAllObjects];
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
        NSString *itemFullpath = [NSString stringWithFormat:@"%@/%@", basicSearchPath, item];   /* full path for item of basicSearchDirectory */
        NSArray *itemContents = [fm contentsOfDirectoryAtPath:itemFullpath error:&error];   /* list of sub-items in item */
        
        if (!itemContents)
            continue;
        
        /*
         * These variable is set only if the following loop fails to locate
         *  Theme but does locate Widget.
         */
        BOOL foundWidget = NO;
        
        for (NSString *subItem in itemContents)
        {
            if ([[subItem pathExtension] isEqualToString:@"cmtheme"] || [subItem isEqualToString:@"themerc.plist"])
            {
                BOOL useNewThemeRCFormat = [subItem isEqualToString:@"themerc.plist"] ? YES : NO;
                NSString *themeRC = [NSString stringWithFormat:@"%@/%@", itemFullpath, (useNewThemeRCFormat ? @"themerc.plist" : subItem)];
                
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
                
                /*
                 * subItem definitely isn't a Theme but it could be a Widget.
                 * Check if it really is and set the appropriate variables.
                 */
                if ([[subItem pathExtension] isEqualToString:@""])
                {
                    NSString *widgetRCFullpath = [NSString stringWithFormat:@"%@/%@", itemFullpath, subItem];
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
        preview = [[widget itemPath] stringByAppendingString:@".jpg"];
    }
    else if (whatToShow == widgetsThemesTableShowThemes)
    {
        MCTheme *theme = [themesArray objectAtIndex:row];
        NSString *themeRoot = [[theme themeRC] stringByDeletingLastPathComponent];
        NSString *themeName = [themeRoot lastPathComponent];
        preview = [NSString stringWithFormat:@"%@/%@.jpg", themeRoot, themeName];
    }
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:preview];
    
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
        str = [[arr objectAtIndex:row] themeRC];
    }
    
    if ([[tableColumn identifier] isEqualToString:@"CollumnA"])
    {
        BOOL isEnabled = [[arr objectAtIndex:row] isEnabled];
        return [NSNumber numberWithBool:isEnabled];
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
        [widget reenable];
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
    
    MCWidget *widget = [widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]];
    
    /*
     * Initialise popover view controller
     */
    if (!editorController)
        editorController = [[MCConfigEditor alloc] initWithNibName:@"Editor" bundle:nil];
    
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
    [editorPopover setContentSize:[editorController view].bounds.size];

    /*
     * Show popover
     */
    [editorPopover showRelativeToRect:[sender bounds]
                               ofView:sender
                        preferredEdge:NSMaxXEdge];
    
    /*
     * Fill editorView with contents.
     * This should go after editorView gets initialised;
     *  thus after showing it for atleast once.
     */
    [editorController loadConfig:[widget itemPath]];
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

@end
