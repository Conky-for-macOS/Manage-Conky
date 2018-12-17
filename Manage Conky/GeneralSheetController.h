//
//  AppController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define GSC_MODE_WINDOW 1

@interface GeneralSheetController : NSWindowController

@property NSUInteger mode;  /* some of our sheets implement different behavior
                             * based on the mode you set! :) */

@property BOOL openWindowed;

@property NSWindow *targetWindow;

- (id)initWithWindowNibName:(NSString *)nibName andMode:(NSUInteger)mode;
- (void)loadOnWindow:(NSWindow *)_targetWindow;
- (IBAction)close:(id)sender;

@end
