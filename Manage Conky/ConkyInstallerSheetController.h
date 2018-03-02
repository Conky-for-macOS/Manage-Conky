//
//  ConkyInstallerSheetController.h
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 02/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface ConkyInstallerSheetController : NSObject

@property (strong) IBOutlet NSPanel *window;
@property (weak) IBOutlet NSTextField *logField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;

- (void)beginInstalling;

@end
