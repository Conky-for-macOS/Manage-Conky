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

#import <LzmaSDKObjC.h>
#import <LzmaSDKObjCReader.h>

@implementation ConkyThemesSheetController

- (IBAction)activateThemesSheet:(id)sender
{
    [super activateSheet:@"ConkyThemes"];
}

/**
 Here happens all the graphicall stuff for showing the list of themes in the theme-pack file
 and giving the option to select and and install any number of themes...
 */
- (void)showThemesList
{
    /* HI! */
    NSLog(@"Omaewa mo sindeiru");
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
        NSLog(@"Failed creating Lzma Reader.");
        return NO;
    }
    
    if (![themePackReader open:&error])
    {
        NSLog(@"Open error: %@", error);
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
            [items addObject:item];
            return YES;
        }
        else
        {
            NSLog(@"Error %@ iterating for item: %@", error, item);
            return NO;
        }
    }];
    
    /*
     * check if succeeded
     */
    return ([items count] == [themePackReader itemsCount]) ? YES : NO;
}

- (IBAction)importFromDefaultThemePack:(id)sender
{
    BOOL res = NO;
    
    NSURL *defaultThemePackPath = [[NSBundle mainBundle] URLForResource:@"default-themes-2.1.cmtp" withExtension:@"7z"];
    res = [self openThemePackWithURL:defaultThemePackPath];
    
    if (res)
        [self showThemesList];
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
    [panel beginWithCompletionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSURL *theDocument = [[panel URLs]objectAtIndex:0];
            res = [self openThemePackWithURL:theDocument];
        }
        else return;
        
        /*
         * show the list
         */
        if (res)
            [self showThemesList];
    }];
}

@end
