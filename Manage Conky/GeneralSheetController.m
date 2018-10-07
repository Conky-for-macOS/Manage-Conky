//
//  AppController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"

@implementation GeneralSheetController

- (void)activateSheet:(NSString*)nibName withOwner:(id)owner
{
    if (!_sheet)
        [[NSBundle mainBundle] loadNibNamed:nibName owner:owner topLevelObjects:nil];
    
    [[NSApp mainWindow] beginSheet:self.sheet completionHandler:^(NSModalResponse returnCode) {}];
}

- (void)activateSheet:(NSString*)nibName
{
    [self activateSheet:nibName withOwner:self];
}

- (IBAction)closeSheet:(id)sender
{
    [[NSApp mainWindow] endSheet:self.sheet];
    self.sheet = nil;
}

@end

@implementation GeneralSheetController0

- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    return self;
}

- (void)loadOnWindow:(NSWindow *)targetWindow
{
    [targetWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
        [targetWindow endSheet:self.window];
    }];
}

- (IBAction)close:(id)sender
{
    [self.window close];
}

@end
