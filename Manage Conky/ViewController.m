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
+ (instancetype)themeOrWidgetWithPid:(pid_t)pid andPath:(NSString * _Nullable)path
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
    
    widgetsArray = [[NSMutableArray alloc] init];
    themesArray = [[NSMutableArray alloc] init];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator;
    
    NSString *basicSearchPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    NSArray *additionalSearchPaths = [[NSUserDefaults standardUserDefaults] objectForKey:@"additionalSearchPaths"];
    
    if (!basicSearchPath)
        return;
    
    enumerator = [fm enumeratorAtPath:basicSearchPath];
    for (NSString *path in enumerator)
    {
        /* fullpath */
        NSString *fullpath = [NSString stringWithFormat:@"%@/%@", basicSearchPath, path];
        
        MCThemeOrWidget *themeOrWidget = [MCThemeOrWidget themeOrWidgetWithPid:MC_PID_NOT_SET andPath:fullpath];
        
        if ([path isEqualToString:@".DS_Store"])
            continue;
        
        /*
         * Empty extension means we found conky config file
         */
        if ([[path pathExtension] isEqualToString:@""] || [[path pathExtension] isEqualToString:@"conf"])
            [widgetsArray addObject:themeOrWidget];
        else if ([[path pathExtension] isEqualToString:@"cmtheme"])
            [themesArray addObject:themeOrWidget];
    }
    
    for (NSString *additionalPath in additionalSearchPaths)
    {
        enumerator = [fm enumeratorAtPath:additionalPath];
        for (NSString *path in enumerator)
        {
            /* fullpath */
            NSString *fullpath = [NSString stringWithFormat:@"%@/%@", additionalPath, path];

            
            MCThemeOrWidget *themeOrWidget = [MCThemeOrWidget themeOrWidgetWithPid:MC_PID_NOT_SET andPath:fullpath];
            
            // handle bad file types
        }
    }
    
    [_widgetsThemesTable setDelegate:self];
    [_widgetsThemesTable setDataSource:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (IBAction)changeTableContents:(id)sender
{
   if ([[sender title] isEqualToString:@"Themes"])
       whatToShow = widgetsThemesTableShowThemes;
    if ([[sender title] isEqualToString:@"Widgets"])
        whatToShow = widgetsThemesTableShowWidgets;
    
    [_widgetsThemesTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (whatToShow == widgetsThemesTableShowWidgets) ? [widgetsArray count] : [themesArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSArray *arr = (whatToShow == widgetsThemesTableShowWidgets) ? widgetsArray : themesArray;
    NSString *str = (whatToShow == widgetsThemesTableShowWidgets) ? [[arr objectAtIndex:row] itemPath] : [[arr objectAtIndex:row] itemPath];
    
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
    NSString *path = [[widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]] itemPath];
    NSString *cmd = [NSString stringWithFormat:@"/usr/local/bin/conky -c %@", path];
    
    NSLog(@"%@", cmd);
    
    system([cmd UTF8String]);
}
- (IBAction)stopWidget:(id)sender
{
    NSInteger i = [_widgetsThemesTable selectedRow];
    pid_t pid = [[widgetsArray objectAtIndex:i] pid];
    kill(pid, SIGINT);
}
- (IBAction)stopAllWidgets:(id)sender
{
    for (MCThemeOrWidget *widget in widgetsArray)
    {
        pid_t pid = [widget pid];
        if (pid != MC_PID_NOT_SET)
            kill(pid, SIGINT);
    }
}

@end
