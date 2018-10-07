//
//  AppController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"


@implementation GeneralSheetController0

- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    return self;
}

- (void)loadOnWindow:(NSWindow *)_targetWindow
{
    self.targetWindow = _targetWindow;
    [_targetWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
        [_targetWindow endSheet:self.window];
    }];
}

- (IBAction)close:(id)sender
{
    [self.window close];
}

@end
