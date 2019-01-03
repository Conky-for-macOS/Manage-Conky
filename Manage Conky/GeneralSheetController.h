//
//  AppController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum MC_GENERAL_SHEET_FLAGS {
    GSC_MODE_NOMODE = 0,
    GSC_MODE_WINDOW
};

@interface GeneralSheetController : NSWindowController<NSWindowDelegate>

@property NSUInteger mode;  /* some of our sheets implement different behavior
                             * based on the mode you set! :) */

@property BOOL opensWindowed;

@property NSWindow *targetWindow;

- (id)initWithWindowNibName:(NSString *)nibName andMode:(NSUInteger)mode;
- (void)loadOnWindow:(NSWindow *)_targetWindow;
- (void)loadAsWindow;
- (IBAction)close:(id)sender;

@end
