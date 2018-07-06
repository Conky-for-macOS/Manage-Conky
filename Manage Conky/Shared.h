//
//  Shared.h
//  Manage Conky
//
//  Created by npyl on 27/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#ifndef Shared_h
#define Shared_h

#import <Cocoa/Cocoa.h>
#import "Extensions/NSAlert+runModalSheet.h"

//
// Contains stuff used by more than one subprojects or files
//

#define HELPER_FINISHED_MESSAGE "I am done here..."     /* msg sent when Helper is quitting */

#define kSMJOBBLESSHELPER_IDENTIFIER @"org.npyl.ManageConkySMJobBlessHelper"
#define SMJOBBLESSHELPER_IDENTIFIER "org.npyl.ManageConkySMJobBlessHelper"

//
// HELPER FUNCTIONS
//
void showErrorAlertWithMessageForWindow(NSString* msg, NSWindow* window);

/**
 * Return ManageConky directory path in ~/Library
 */
NSString *MCDirectory(void);

/**
 * Create ManageConky directory in ~/Library
 */
BOOL createMCDirectory(void);

/**
 * Create LaunchAgents directory at ~/Library if it doesn't exist
 */
void createUserLaunchAgentsDirectory(void);

BOOL isLaunchAgentEnabled(NSString *label);

BOOL removeLaunchAgent(NSString* label);

BOOL createLaunchAgent(NSString *label,
                       NSArray *args,
                       BOOL keepAlive,
                       NSUInteger throttle,
                       NSString *workingDirectory);

#endif /* Shared_h */
