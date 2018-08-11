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

#import "LzmaSDKObjC.h"
#import "ViewController.h"
#import "LzmaSDKObjCReader.h"
#import "SaveThemeSheetController.h"

@implementation ConkyThemesSheetController

- (IBAction)activateThemesSheet:(id)sender
{
    [super activateSheet:@"ConkyThemes"];
}

/**
 * Fill the widgets/themes table in main window
 */
- (void)fillWidgetsThemesTable
{
    /* HI! */
    NSLog(@"Omaewa mo sindeiru");
    
    /*
     * Get pointer to the one-and-only ViewController instance,
     *  which is also the table's delegate and data-source.
     *
     *  Call the method `fillWidgetsThemesArrays` and fill the arrays
     *  with data in order to reload table, with newly installed themes/widgets.
     */
    ViewController *pVC = [_themesOrWidgetsTable delegate];
    [pVC emptyWidgetsThemesArrays];
    [pVC fillWidgetsThemesArrays];
    [_themesOrWidgetsTable reloadData];
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
    
    /*
     *  fill the array with the zip-file items
     */
    items = [NSMutableArray array];
    
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
    BOOL res = FALSE;
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
    res = [themePackReader extract:items toPath:path withFullPaths:YES];
    
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
    [self.sheet beginSheet:panel completionHandler:^(NSModalResponse result) {
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
    SaveThemeSheetController *controller = [[SaveThemeSheetController alloc] initWithWindowNibName:@"SaveTheme"];
    [self.sheet beginSheet:controller.window completionHandler:^(NSModalResponse returnCode) {
        [self.sheet endSheet:controller.window];
    }];
}

@end
