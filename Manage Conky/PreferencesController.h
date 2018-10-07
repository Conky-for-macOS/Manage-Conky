//
//  PreferencesController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 04/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"

@interface PreferencesController : GeneralSheetController

@property (weak) IBOutlet NSButton *loggingToggle;
@property (weak) IBOutlet NSView *logfileLocation;

@end
