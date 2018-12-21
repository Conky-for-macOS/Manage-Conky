//
//  AppController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects/MCObjects.h"
#import "GeneralSheetController.h"

@implementation GeneralSheetController

- (id)initWithWindowNibName:(NSString *)nibName andMode:(NSUInteger)mode
{
    self = [super initWithWindowNibName:nibName];
    
    if (self)
    {
        self.mode = mode;
        _opensWindowed = (_mode & GSC_MODE_WINDOW);
    }
    
    return self;
}

- (void)loadOnWindow:(NSWindow *)_targetWindow
{
    self.targetWindow = _targetWindow;
    
    if (_opensWindowed)
    {
        [self showWindow:self];
    }
    else
    {
        [_targetWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
            [_targetWindow endSheet:self.window];
        }];
        
        [[MCSettings sharedSettings] pushWindow:self.window];
    }
}

- (IBAction)close:(id)sender
{
    [self.window close];
    
    if (!_opensWindowed)
    {
        [[MCSettings sharedSettings] popWindow];
    }
}

@end
