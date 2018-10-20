//
//  ConkyPreferencesSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 09/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"
#import <Sparkle/Sparkle.h>

/**
 * Formatter for allowing only integer values and more...
 *  for startupDelay text field.
 *
 * Help from: https://stackoverflow.com/questions/12161654/restrict-nstextfield-to-only-allow-numbers
 */
@interface OnlyIntegerValueFormatter : NSNumberFormatter
@end


@interface ConkyPreferencesSheetController : GeneralSheetController<SUUpdaterDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>
{
    BOOL conkyXInstalled;
    BOOL conkyInstalled;
    BOOL xquartzQuitAlertDisabled;
    
    BOOL keepAlive;
    
    BOOL mustDisableConkyForStartup;
    BOOL mustEnableConkyForStartup;
    BOOL mustAddSearchPaths;
    
    NSMutableArray *_oldSearchLocationsTableContents;
    NSMutableArray *_searchLocationsTableContents;
}

// Run Conky At Startup
@property (weak) IBOutlet NSButton *runConkyAtStartupCheckbox;

// Install/Uninstall Button
@property (weak) IBOutlet NSButton *un_in_stallConkyButton;

// Conky Config Files Location
@property (weak) IBOutlet NSTextField *conkyConfigFilesLocationLabel;
@property (weak) IBOutlet NSTextField *conkyConfigLocationTextfield;
@property (weak) IBOutlet NSButton *setConkyConfigFilesLocationButton;

// Startup Delay
@property (weak) IBOutlet NSTextField *startupDelayField;
@property (weak) IBOutlet NSStepper *startupDelayStepper;
@property (weak) IBOutlet NSTextField *startupDelayLabel;

// Additional Search Locations
@property (weak) IBOutlet NSTableView *searchLocationsTable;
@property (weak) IBOutlet NSButton *addSearchLocationButton;
@property (weak) IBOutlet NSButton *removeSearchLocationButton;
@property (weak) IBOutlet NSTextField *additionalLocationsToSearchLabel;

// XQuartz warnings
@property (weak) IBOutlet NSButtonCell *disableXQuartzWarningsCheckbox;
@property (weak) IBOutlet NSButtonCell *toggleXQuartzIconVisibilityCheckbox;

// Changes Applied
@property (weak) IBOutlet NSTextField *changesSavedLabel;
@property (weak) IBOutlet NSButton *applyChangesButton;
@property (weak) IBOutlet NSButton *doneButton;

- (void)initStuff;

@end
