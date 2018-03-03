//
//  ConkyInstallerSheetController.h
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 02/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "GeneralSheetController.h"

@interface ConkyInstallerSheetController : NSViewController

@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *logField;
@property (weak) IBOutlet NSButton *doneButton;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (void)beginInstalling;

@end
