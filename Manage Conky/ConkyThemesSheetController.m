//
//  ConkyThemesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

//
// NOTE:  For Lzma Library to work we need to have selected the type of the library to dynamic library
//

#import "ConkyThemesSheetController.h"

#import "Shared.h"
#import "LzmaSDKObjC.h"
#import "ViewController.h"
#import "LzmaSDKObjCReader.h"
#import "SaveThemeSheetController.h"
#import "SaveWidgetSheetController.h"


@implementation ConkyThemesSheetController

/**
 * Fill the widgets/themes table in main window
 */
- (void)fillWidgetsThemesTable
{
    /* HI! */
    NSLog(@"Omaewa mo sindeiru");
    
    /* refresh List of Widgets/Themes */
    [[[MCSettings sharedSettings] mainViewController] updateWidgetsThemesArray];
}

- (BOOL)openThemePackWithURL:(NSURL*)url
{
    /*
     * Open theme-pack
     */
    NSError * error = nil;
    LzmaSDKObjCReader * themePackReader = [[LzmaSDKObjCReader alloc] initWithFileURL:url andType:LzmaSDKObjCFileType7z];
    
    if (!themePackReader)
    {
        NSLog(@"Error: Failed creating Lzma Reader.");
        return NO;
    }
    
    if (![themePackReader open:&error])
    {
        NSLog(@"Error: Failed to open themepack with error: \n\n%@", error);
        return NO;
    }

    items = [NSMutableArray array];

    /*
     *  fill the array with the zip-file items
     */
    [themePackReader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error)
    {
        if (item)
        {
            [self->items addObject:item];
            return YES;
        }
        else
        {
            NSLog(@"Error %@ iterating for item: %@", error, item);
            return NO;
        }
    }];
    
    /*
     * Extract themepack
     */
    BOOL res = NO;
    /* XXX
     * The first time you run MC on your computer and click import default
     * themepack, it is supposed to already have set the default config
     * location to `/Users/____/Documents/Conky`, but for some reason this
     * is not the case.
     */
    res = [themePackReader extract:items
                            toPath:[[MCSettings sharedSettings] configsLocation]
                     withFullPaths:YES];
    
    /*
     * check if succeeded
     */
    return (res && ([items count] == [themePackReader itemsCount]));
}

- (IBAction)importFromDefaultThemePack:(id)sender
{
    BOOL res = NO;
    
    NSURL *defaultThemePackPath = [[NSBundle mainBundle] URLForResource:@"default-themes-2.1.cmtp" withExtension:@"7z"];
    res = [self openThemePackWithURL:defaultThemePackPath];
    
    if (res)
        [self fillWidgetsThemesTable];
}

- (IBAction)importFromCustomThemePack:(id)sender
{
    /*
     * create an open documet panel
     */
    __block BOOL res = NO;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = @[@"7z"];
    
    /*
     * display the panel
     */
    [self.window beginSheet:panel completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK)
        {
            NSURL *theDocument = [[panel URLs]objectAtIndex:0];
            res = [self openThemePackWithURL:theDocument];
        }
        else return;
        
        /*
         * show the list
         */
        if (res)
            [self fillWidgetsThemesTable];
    }];
}

- (IBAction)createTheme:(id)sender
{
    [[[SaveThemeSheetController alloc] initWithWindowNibName:@"SaveTheme"] loadOnWindow:self.window];
}

- (IBAction)createWidget:(id)sender
{
    [[[SaveWidgetSheetController alloc] initWithWindowNibName:@"SaveWidget"] loadOnWindow:self.window];
}

@end
