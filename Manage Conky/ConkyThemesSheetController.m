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

- (void)openThemePackWithURL:(NSURL*)url
{
    //    themePackReader.delegate = self;          --- Extract progress
    
    
    LzmaSDKObjCReader * themePackReader = [[LzmaSDKObjCReader alloc] initWithFileURL:url
                                                                             andType:LzmaSDKObjCFileType7z];
    
    if (!themePackReader) {
        NSLog( @"Failed creating Lzma Reader." );
        return;
    }
    
    NSError * error = nil;
    if (![themePackReader open:&error]) {
        NSLog(@"Open error: %@", error);
        return;
    }
    
    NSMutableArray * items = [NSMutableArray array];
    
    [themePackReader iterateWithHandler:^BOOL(LzmaSDKObjCItem * item, NSError * error) {
        NSLog(@"\n%@", item);
        
        if (item) [items addObject:item];                                                       /* if needs this item - store to array */
        
        return YES;                                                                             /* YES - continue iterate, NO - stop iteration */
    }];

}

- (IBAction)importFromDefaultThemePack:(id)sender
{
    NSString *defaultThemePackPath = [NSString stringWithFormat:@"%@/default-themes-2.1.cmtp.7z", [[NSBundle mainBundle] resourcePath]];
    [self openThemePackWithURL:[NSURL fileURLWithPath:defaultThemePackPath]];
}

- (IBAction)importFromCustomThemePack:(id)sender
{
    // create an open documet panel
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    
    // display the panel
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSURL *theDocument = [[panel URLs]objectAtIndex:0];
            NSString *archivePath = [NSString stringWithFormat:@"%@", theDocument];
            
            NSLog(@"%@", archivePath);
            
            [self openThemePackWithURL:theDocument];
        }
    }];
}

@end
