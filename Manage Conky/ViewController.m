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
                
        // XXX if we find a .cmtheme file inside a widget/theme (we don't know yet), treat as theme, thus add to themesArray
        
        /*
         * Empty extension means we found conky config file
         */
        if ([[item pathExtension] isEqualToString:@""] || [[item pathExtension] isEqualToString:@"conf"])
        {
            [widgetsArray addObject:[MCWidget widgetWithPid:MC_PID_NOT_SET andPath:fullpath]];
        }
        else if ([[item pathExtension] isEqualToString:@"cmtheme"])
        {
            MCTheme *theme = [MCTheme themeRepresentationForPath:fullpath];
            if (!theme)
                continue;
            [themesArray addObject:theme];
        }
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
            
            /*
             * Empty extension means we found conky config file
             */
            if ([[item pathExtension] isEqualToString:@""] || [[item pathExtension] isEqualToString:@"conf"])
            {
                [widgetsArray addObject:[MCWidget widgetWithPid:MC_PID_NOT_SET andPath:fullpath]];
            }
            else if ([[item pathExtension] isEqualToString:@"cmtheme"])
            {
                MCTheme *theme = [MCTheme themeRepresentationForPath:fullpath];
                if (!theme)
                    continue;
                [themesArray addObject:theme];
            }
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
        MCWidget *widget = [widgetsArray objectAtIndex:row];

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
