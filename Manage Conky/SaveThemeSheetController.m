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
    }
    return self;
}

- (IBAction)saveTheme:(id)sender
{
    NSString *basicSearchPath = [[MCSettings sharedInstance] configsLocation];
    NSString *path = [basicSearchPath stringByAppendingPathComponent:_name];
    
    NSMutableDictionary *themerc = [NSMutableDictionary dictionary];
    
    /*
     * Set the values
     */
    _name = _themeNameField.stringValue;
    propertiesFilledIn++;
    
    /*
     * Check if user has filled-in all info
     */
    if (propertiesFilledIn != MC_MAX_PROPERTIES)
    {
        NSExtendedAlert *alert = [[NSExtendedAlert alloc] init];
        [alert setMessageText:@"Whoa! Hold your horses!"];
        [alert setInformativeText:@"You forgot to fill in some info."];
        [alert setAlertStyle:NSAlertStyleCritical];
        [alert runModalSheetForWindow:self.window];
    }
    
    /*
     * Set dictionary
     */
    [themerc setObject:_wallpaper forKey:@"wallpaper"];
    [themerc setObject:_conkyConfigs forKey:@"conkyConfigs"];
    [themerc setObject:_source forKey:@"source"];
    [themerc setObject:_creator forKey:@"creator"];
    
    [themerc writeToFile:[path stringByAppendingPathComponent:@"themerc.plist"]
              atomically:YES];
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
}

- (IBAction)chooseScaling:(id)sender
{
    
}

- (IBAction)closeButton:(id)sender
{
    [self.window close];
}

@end
