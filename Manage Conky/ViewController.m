//
//  ViewController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ViewController.h"

#define MC_PID_NOT_SET (-100)

@implementation MCThemeOrWidget
+ (instancetype)themeOrWidgetWithPid:(pid_t)pid andPath:(NSString *)path
{
    id res = [[self alloc] init];
    [res setPid:pid];
    [res setItemPath:path];
    return res;
}
@end

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

/*
 * Applies a theme to computer by:
 *  - applying conky config
 *  - applying wallpaper
 *
 * supports two types of themes:
 *  - original conky-manager themes (plain files with minimal info) (backwards compatibility)
 *  - plist based (support many parameters/features in a native macOS way)
 */
- (void)applyTheme:(MCThemeOrWidget *)theme
{
    NSString *themeRoot = [[theme itemPath] stringByDeletingLastPathComponent];
    NSString *themeRCFile = [themeRoot stringByAppendingString:@"/themerc.plist"];
    
    /*
     * Information extracted from theme info file
     */
    NSInteger startupDelay = 0;
    NSString *conkyConfig = nil;
    NSArray *arguments = nil;
    NSString *wallpaper = nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    /*
     * Check if we can use a themerc.plist
     */
    if ([fm fileExistsAtPath:themeRCFile])
    {
        /*
         * Doing it the ManageConky way...
         */
        
        NSDictionary *rc = [NSDictionary dictionaryWithContentsOfFile:themeRCFile];
        
        //startupDelay = [rc objectForKey:@"startupDelay"];
        conkyConfig = [rc objectForKey:@"config"];
        arguments = [rc objectForKey:@"args"];
        wallpaper = [rc objectForKey:@"wallpaper"];
    }
    else
    {
        /*
         * Doing it the conky-manager way...
         */
        themeRCFile = nil;
        
        NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:themeRoot];
        for (NSString *item in enumerator)
        {
            if ([[item pathExtension] isEqualToString:@"cmtheme"])
            {
                themeRCFile = [NSString stringWithFormat:@"%@/%@", themeRoot, item];
                break;
            }
        }
        
        /*
         * Check if we got something
         */
        if (!themeRCFile)
            return;
        
        /*
         * Start reading the file
         */
    }
}

//
// DATA ARRAYS CONTROL
//

- (void)emptyWidgetsThemesArrays
{
    [widgetsArray removeAllObjects];
    [themesArray removeAllObjects];
}

- (void)fillWidgetsThemesArrays
{
    widgetsArray = [[NSMutableArray alloc] init];
    themesArray = [[NSMutableArray alloc] init];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator;
    
    NSString *basicSearchPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    NSArray *additionalSearchPaths = [[NSUserDefaults standardUserDefaults] objectForKey:@"additionalSearchPaths"];
    
    if (!basicSearchPath)
        return;
    
    enumerator = [fm enumeratorAtPath:basicSearchPath];
    for (NSString *item in enumerator)
    {
        /* fullpath */
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", basicSearchPath, item];
        
        BOOL isDirectory = NO;
        [fm fileExistsAtPath:fullpath isDirectory:&isDirectory];
        if (isDirectory)
            continue;
        
        if ([[item lastPathComponent] isEqualToString:@".DS_Store"])
            continue;
        
        MCThemeOrWidget *themeOrWidget = [MCThemeOrWidget themeOrWidgetWithPid:MC_PID_NOT_SET andPath:fullpath];
        
        // XXX if we find a .cmtheme file inside a widget/theme (we don't know yet), treat as theme, thus add to themesArray
        
        /*
         * Empty extension means we found conky config file
         */
        if ([[item pathExtension] isEqualToString:@""] || [[item pathExtension] isEqualToString:@"conf"])
            [widgetsArray addObject:themeOrWidget];
        else if ([[item pathExtension] isEqualToString:@"cmtheme"])
            [themesArray addObject:themeOrWidget];
        else continue;
    }
    
    for (NSString *additionalPath in additionalSearchPaths)
    {
        enumerator = [fm enumeratorAtPath:additionalPath];
        for (NSString *item in enumerator)
        {
            /* fullpath */
            NSString *fullpath = [NSString stringWithFormat:@"%@/%@", additionalPath, item];
            
            BOOL isDirectory = NO;
            [fm fileExistsAtPath:fullpath isDirectory:&isDirectory];
            if (isDirectory)
                continue;
            
            if ([[item lastPathComponent] isEqualToString:@".DS_Store"])
                continue;
            
            MCThemeOrWidget *themeOrWidget = [MCThemeOrWidget themeOrWidgetWithPid:MC_PID_NOT_SET andPath:fullpath];
            
            /*
             * Empty extension means we found conky config file
             */
            if ([[item pathExtension] isEqualToString:@""] || [[item pathExtension] isEqualToString:@"conf"])
                [widgetsArray addObject:themeOrWidget];
            else if ([[item pathExtension] isEqualToString:@"cmtheme"])
                [themesArray addObject:themeOrWidget];
            else continue;
        }
    }
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
    
    /*
     *  If user selected a widget show preview.
     *  Otherwise give the ability to apply a theme.
     */
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        MCThemeOrWidget *widget = [widgetsArray objectAtIndex:row];

        /*
         * For conky-manager all preview files all jpeg and follow the naming: widgetName.jpg
         */
        NSString *preview = [[widget itemPath] stringByAppendingString:@".jpg"];
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
    else if (whatToShow == widgetsThemesTableShowThemes)
    {
        
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (whatToShow == widgetsThemesTableShowWidgets) ? [widgetsArray count] : [themesArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSArray *arr = (whatToShow == widgetsThemesTableShowWidgets) ? widgetsArray : themesArray;
    NSString *str = [[arr objectAtIndex:row] itemPath];
    
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
    /* guard */
    if (whatToShow == widgetsThemesTableShowThemes)
        return;
    
    NSString *path = [[widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]] itemPath];
    
    // check if already running to restart
    pid_t tmp = [[widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]] pid];
    if (tmp != MC_PID_NOT_SET)
        [self stopWidget:nil];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/local/bin/conky"];
    [task setArguments:@[@"-c", path]];
    [task setCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
    [task launch];
    
    pid_t pid = [task processIdentifier];
    [[widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]] setPid:pid];
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
    
    for (MCThemeOrWidget *widget in widgetsArray)
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
