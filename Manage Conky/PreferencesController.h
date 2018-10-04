//
//  PreferencesController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreferencesController : NSWindowController

@property (strong) IBOutlet NSWindow *window;

- (id)initWithWindowNibName:(NSString *)nibName;

@end

NS_ASSUME_NONNULL_END
