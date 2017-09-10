//
//  ConkyThemesSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyThemesSheetController.h"

@implementation ConkyThemesSheetController

- (IBAction)activateThemesSheet:(id)sender
{
    [super activateSheet:@"ConkyThemes"];
}

- (IBAction)importThemePack:(id)sender
{
    // create an open documet panel
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    
    // display the panel
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSURL *theDocument = [[panel URLs]objectAtIndex:0];
            NSString *theString = [NSString stringWithFormat:@"%@", theDocument];
            
            NSLog(@"%@", theString);
        }
    }];
}

@end
