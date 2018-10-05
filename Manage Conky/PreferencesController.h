//
//  PreferencesController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesController : NSWindowController

@property (strong) IBOutlet NSWindow *window;

- (id)initWithWindowNibName:(NSString *)nibName;

@end
