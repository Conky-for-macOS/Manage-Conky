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
- (instancetype)initWithPid:(pid_t)pid_ andPath:(NSString *)path_
{
    pid = pid_;
    path = path_;
    return [self init];
}
- (NSString *)path
{
    return path;
}
- (pid_t)pid
{
    return pid;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    /*
     * Setup stuff
     */
    
    whatToShow = widgetsThemesTableShowWidgets; /* initial value */
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator;
    
    NSString *basicSearchPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    NSArray *additionalSearchPaths = [[NSUserDefaults standardUserDefaults] objectForKey:@"additionalSearchPaths"];
    
    if (!basicSearchPath)
        return;
    
    enumerator = [fm enumeratorAtPath:basicSearchPath];
    for (NSString *path in enumerator)
    {
        MCThemeOrWidget *themeOrWidget = [[MCThemeOrWidget alloc] initWithPid:MC_PID_NOT_SET andPath:path];
        
        [[path pathExtension] isEqualToString:@"conkyTheme"] ?
        [themesArray addObject:themeOrWidget] :
        [widgetsArray addObject:themeOrWidget];
    }
    
    for (NSString *additionalPath in additionalSearchPaths)
    {
        enumerator = [fm enumeratorAtPath:additionalPath];
        for (NSString *path in enumerator)
        {
            MCThemeOrWidget *themeOrWidget = [[MCThemeOrWidget alloc] initWithPid:MC_PID_NOT_SET andPath:path];
            
            [[path pathExtension] isEqualToString:@"conkyTheme"] ?
            [themesArray addObject:themeOrWidget] :
            [widgetsArray addObject:themeOrWidget];
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
    NSString *str = (whatToShow == widgetsThemesTableShowWidgets) ? [[widgetsArray objectAtIndex:row] path] : [[themesArray objectAtIndex:row] path];
    
    if (whatToShow == widgetsThemesTableShowWidgets)
    {
        if ([[tableColumn identifier] isEqualToString:@"CollumnA"])
        {
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"CellAID" owner:nil];
            // checkbox: ticked or not?
            return cell;
        }
        else
        {
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"CellBID" owner:nil];
            cell.textField.stringValue = str;
            return cell;
        }
    }
    else return nil;
}

//
// CONKY CONTROL
//
- (IBAction)startOrRestartWidget:(id)sender
{
    NSString *path = [[widgetsArray objectAtIndex:[_widgetsThemesTable selectedRow]] path];
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
