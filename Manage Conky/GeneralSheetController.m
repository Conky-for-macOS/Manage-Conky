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
        
        /* Enable App Termination if Window is Modal */
        [[super window] setPreventsApplicationTerminationWhenModal:NO];
    }
    return self;
}

- (id)initWithWindowNibName:(NSString *)nibName
{
    return [self initWithWindowNibName:nibName andMode:GSC_MODE_NOMODE];
}

- (void)loadOnWindow:(NSWindow *)_targetWindow
{
    self.targetWindow = _targetWindow;
    
    if (_opensWindowed)
    {
        NSException *ex = [NSException exceptionWithName:@"MCAPIException" reason:@"InvalidUseOf_LOAD_ON_WINDOW()" userInfo:nil];
        @throw ex;
        return;
    }
    else
    {
        [_targetWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
            [_targetWindow endSheet:self.window];
        }];
        
        [[MCSettings sharedSettings] pushWindow:self.window];
    }
}

- (void)loadAsWindow
{
    /* first take care of the flags */
    _mode |= GSC_MODE_WINDOW;
    _opensWindowed = YES;
    
    [super showWindow:self];
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
