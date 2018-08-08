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
#import "MCFilesystem.h"
#import "Extensions/NSAlert+runModalSheet.h"

/* defines */
#define CONKYX              @"/Applications/ConkyX.app"
#define MANAGE_CONKY        @"/Applications/Manage Conky.app"
#define CONKY_SYMLINK       @"/usr/local/bin/conky"
#define LAUNCH_AGENT_PREFIX @"org.npyl.ManageConky.Widget"

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
 * Create LaunchAgents directory at ~/Library if it doesn't exist
 */
void createUserLaunchAgentsDirectory(void);

BOOL isLaunchAgentEnabled(NSString *label);

BOOL removeLaunchAgent(NSString* label);

void createLaunchAgent(NSString *label,
                       NSArray *args,
                       BOOL keepAlive,
                       NSUInteger throttle,
                       NSString *workingDirectory,
                       NSError *error);

#endif /* Shared_h */
