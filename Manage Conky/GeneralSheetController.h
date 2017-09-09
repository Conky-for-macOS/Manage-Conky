//
//  AppController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface GeneralSheetController : NSObject

@property (assign) IBOutlet NSWindow * sheet;

- (void)activateSheet:(NSString*)nibName;

- (IBAction)closeSheet:(id)sender;

@end
