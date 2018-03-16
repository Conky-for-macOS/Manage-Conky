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
 *
 * Help from: https://stackoverflow.com/questions/12161654/restrict-nstextfield-to-only-allow-numbers
 */
@interface OnlyIntegerValueFormatter : NSNumberFormatter
@end


@interface ConkyPreferencesSheetController : GeneralSheetController
{
    ConkyInstallerSheetController *ctl;
    BOOL conkyXInstalled;
    BOOL conkyAgentPresent;
    
    BOOL keepAlive;
    BOOL mustInstallAgent;
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

@property (weak) IBOutlet NSButton *doneButton;


- (IBAction)activatePreferencesSheet:(id)sender;

@end
