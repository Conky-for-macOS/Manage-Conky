//
//  ConkyPreferencesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"
#import "ConkyInstallerSheetController.h"

/**
 * Formatter for allowing only integer values and more...
 *  for startupDelay text field.
 */
@interface OnlyIntegerValueFormatter : NSNumberFormatter
@end


@interface ConkyPreferencesSheetController : GeneralSheetController
{
    ConkyInstallerSheetController *ctl;
    BOOL conkyXInstalled;
    BOOL conkyAgentPresent;
    
    NSInteger startupDelay;
    BOOL keepAlive;
}

// Run Conky At Startup
@property (weak) IBOutlet NSButton *runConkyAtStartupCheckbox;

// Install/Uninstall Button
@property (weak) IBOutlet NSButton *un_in_stallConkyButton;

// Conky Config Files Location
@property (weak) IBOutlet NSTextField *conkyConfigFilesLocationLabel;
@property (weak) IBOutlet NSTextField *conkyConfigLocationTextfield;

// Startup Delay
@property (weak) IBOutlet NSTextField *startupDelayField;
@property (weak) IBOutlet NSStepper *startupDelayStepper;
@property (weak) IBOutlet NSTextField *startupDelayLabel;


- (IBAction)activatePreferencesSheet:(id)sender;

@end
