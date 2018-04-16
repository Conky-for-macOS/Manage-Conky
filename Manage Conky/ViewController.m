//
//  ViewController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ViewController.h"

// defines
#define MC_PID_NOT_SET (-100)   /* pid not yet set */

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     * Setup stuff
     */
    
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
    widgetsArray = [[NSMutableArray alloc] init];
    themesArray = [[NSMutableArray alloc] init];
    
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
    
    if (!widgetPreviewPopover)
    {
        widgetPreviewPopover = [[NSPopover alloc] init];
        [widgetPreviewPopover setBehavior:NSPopoverBehaviorSemitransient];
        [widgetPreviewPopover setAnimates:YES];
    }
    
    /*
     * close any previously created popover
     */
    [widgetPreviewPopover setAnimates:NO];  /* close without animation */
    [widgetPreviewPopover close];
    [widgetPreviewPopover setAnimates:YES]; /* show with animation */
    
    /*
     * setup a new popover preview
     */
    [widgetPreviewPopover setContentViewController:controller];
    [widgetPreviewPopover setContentSize:[image size]];
    
    /*
     * show the preview
     */
    [widgetPreviewPopover showRelativeToRect:[[notification object] bounds]
                                      ofView:[notification object] preferredEdge:NSMaxXEdge];
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
        pid_t pid = [[arr objectAtIndex:row] pid];
        return [NSNumber numberWithBool:((pid == MC_PID_NOT_SET) ? NO : YES)];
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
    
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        NSString *path = [[widgetsArray objectAtIndex:row] itemPath];
        
        /* check if already running to restart */
        pid_t tmp = [[widgetsArray objectAtIndex:row] pid];
        if (tmp != MC_PID_NOT_SET)
            [self stopWidget:nil];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/local/bin/conky"];
        [task setArguments:@[@"-c", path]];
        [task setCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
        [task launch];
        
        pid_t pid = [task processIdentifier];
        [[widgetsArray objectAtIndex:row] setPid:pid];
    }
    else
    {
        MCTheme *theme = [themesArray objectAtIndex:row];
        [theme applyTheme];
    }
    
    [_widgetsThemesTable reloadData];
}
- (IBAction)stopWidget:(id)sender
{
    /* guard */
    if (whatToShow == widgetsThemesTableShowThemes)
        return;
    
    NSInteger i = [_widgetsThemesTable selectedRow];
    pid_t pid = [[widgetsArray objectAtIndex:i] pid];

    int stat_loc = 0;
    kill(pid, SIGINT);
    waitpid(pid, &stat_loc, WNOHANG);
    
    [[widgetsArray objectAtIndex:i] setPid:MC_PID_NOT_SET];
    [_widgetsThemesTable reloadData];
}
- (IBAction)stopAllWidgets:(id)sender
{
    /* guard */
    if (whatToShow == widgetsThemesTableShowThemes)
        return;
    
    for (MCWidget *widget in widgetsArray)
    {
        pid_t pid = [widget pid];
        if (pid != MC_PID_NOT_SET)
        {
            int stat_loc = 0;
            kill(pid, SIGINT);
            waitpid(pid, &stat_loc, WNOHANG);
            
            [widget setPid:MC_PID_NOT_SET];
        }
    }
    
    [_widgetsThemesTable reloadData];
}

@end
