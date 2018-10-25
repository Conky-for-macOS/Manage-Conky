//
//  AppController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GeneralSheetController : NSWindowController

@property NSWindow *targetWindow;

- (id)initWithWindowNibName:(NSString *)nibName;
- (void)loadOnWindow:(NSWindow *)_targetWindow;
- (IBAction)close:(id)sender;

@end
