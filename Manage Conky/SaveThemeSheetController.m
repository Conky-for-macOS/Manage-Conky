//
//  SaveThemeSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects/MCObjects.h"
#import "SaveThemeSheetController.h"
#import "Extensions/NSAlert+runModalSheet.h"

@implementation SaveThemeSheetController

- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    if (self)
    {
        /*
         * Basic initialisation
         */
        propertiesFilledIn = 0;
        _scaling = FillScreen;
        _relative = YES;
        
        _conkyConfigs = [NSMutableArray array];
        [_widgetsTableView registerForDraggedTypes:@[NSStringPboardType]];
    }
    return self;
}

- (void)awakeFromNib
{
    /* popup button */
    for (int i = 0; i < MAX_SCALING_KEYS; i++)
        [_scalingPopUpButton addItemWithTitle:[NSString stringWithUTF8String:cMacScalingKeys[i]]];

    [_widgetsTableView registerForDraggedTypes:@[NSURLPboardType]]; /*  we only accept files with no-extension*/
}

- (IBAction)saveTheme:(id)sender
{
    /* Set the values */
    _name = _themeNameField.stringValue;
    _source = _themeSourceField.stringValue;
    _creator = _themeCreatorField.stringValue;
    propertiesFilledIn++;

    NSString *basicSearchPath = [[MCSettings sharedInstance] configsLocation];
    NSString *path = [basicSearchPath stringByAppendingPathComponent:_name];

    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];

    /* Check if user has filled-in all info */
    if (propertiesFilledIn != MC_MAX_PROPERTIES)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Whoa! Hold your horses!"];
        [alert setInformativeText:@"You forgot to fill in some info."];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModalSheetForWindow:self.window];

        return;
    }

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
        
        propertiesFilledIn++;
    }
    else
        return;

    /*
     * Keep path relative to theme directory OR full?
     */
    NSAlert *alert = [[NSAlert alloc] init];
    
    alert.informativeText = @"Path relative or Full?";
    alert.messageText = @"Choosing a relative path will tell ManageConky to save the wallpaper inside your theme directory! This way you will never loose the wallpaper!";
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

- (IBAction)closeButton:(id)sender
{
    [self.window close];
}

//
//=========================================================================================================
//

//
// DATA SOURCE
//

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [_widgetsTableView selectedRow];
    
    if (row < 0)
        return;
    
    // xxx
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_conkyConfigs count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0)
        return nil;
    
    NSTextFieldCell *cell = [tableColumn dataCellForRow:row];
    
    /*
     * check if already allocated
     */
    if (!cell)
        cell = [[NSTextFieldCell alloc] init];
    
    cell.stringValue = [_conkyConfigs objectAtIndex:row];
    return cell;
}

//
// DRAG & DROP
//

// What kind of drag operation should I perform?
- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id )info proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op
{
    return NSDragOperationEvery; // Specifies that the drop should occur above the specified row.
}

// The mouse button was released over a row in the table view, should I accept the drop?
- (BOOL)tableView:(NSTableView*)tv
       acceptDrop:(id )info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)op
{
    return YES;
}

@end
