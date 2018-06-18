//
//  ConkyInstallerSheetController.m
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 02/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyInstallerSheetController.h"

#import "Shared.h"
#import "PFMoveApplication.h"
#import "NSAlert+runModalSheet.h"
#import <Foundation/NSFileManager.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ServiceManagement/ServiceManagement.h>

#define MANAGE_CONKY_PATH "/Applications/Manage Conky.app"
#define HOMEBREW_PATH "/usr/local/bin/brew"
#define XQUARTZ_PATH  "/usr/X11"

@implementation ConkyInstallerSheetController

BOOL blessHelperWithLabel(NSString *label, CFErrorRef *error)
{
    BOOL result = NO;
    
    AuthorizationItem authItem        = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights    = { 1, &authItem };
    AuthorizationFlags flags          = kAuthorizationFlagDefaults |
                                        kAuthorizationFlagInteractionAllowed    |
                                        kAuthorizationFlagPreAuthorize    |
                                        kAuthorizationFlagExtendRights;
    
    AuthorizationRef authRef = NULL;
    
    /* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
    OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to create AuthorizationRef. Error code: %d", (int)status);

    } else {
        /* This does all the work of verifying the helper tool against the application
         * and vice-versa. Once verification has passed, the embedded launchd.plist
         * is extracted and placed in /Library/LaunchDaemons and then loaded. The
         * executable is placed in /Library/PrivilegedHelperTools.
         */
        result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)label, authRef, error);
    }
    
    return result;
}

- (void)writeToLog:(NSString *)str
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_logField.stringValue = [self->_logField.stringValue stringByAppendingString:str];
    });
}

- (void)receivedData:(NSNotification*)notif
{
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    if (data.length > 0)
    {
        /* if data is found, re-register for more data (and print) */
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self writeToLog:str];
    }
};

- (void)installMissingLibraries
{
    /*
     * setup the installer script task
     */
    NSPipe *outputPipe = [[NSPipe alloc] init];
    NSPipe *errorPipe = [[NSPipe alloc] init];
    
    NSString *scriptPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/InstallLibraries.sh"];
    
    NSTask *script = [[NSTask alloc] init];
    [script setLaunchPath:@"/bin/sh"];
    [script setArguments:@[scriptPath]];
    [script setStandardOutput:outputPipe];
    [script setStandardError:errorPipe];
    
    NSFileHandle *outputHandle = [outputPipe fileHandleForReading];
    NSFileHandle *errorHandle = [errorPipe fileHandleForReading];
    
    [outputHandle waitForDataInBackgroundAndNotify];
    [errorHandle waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:outputHandle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:errorHandle];
    
    /*
     * run the installer script
     */
    [script launch];
    [script waitUntilExit];
}

- (void)beginInstalling
{
    [_progressIndicator startAnimation:nil];
    
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    /*
     * detect if Homebrew is installed
     */
    if (access(HOMEBREW_PATH, F_OK) != 0)
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://brew.sh"]];
        
        NSExtendedAlert *hbalert = [[NSExtendedAlert alloc] init];
        [hbalert setMessageText:@"Homebrew missing"];
        [hbalert setInformativeText:@"Install Homebrew first using the link I opened in the browser.\nOnce you install click OK to continue"];
        [hbalert setAlertStyle:NSAlertStyleCritical];
        [hbalert runModalSheetForWindow:_window];
    }
    
    
    NSThread *thread1 = [[NSThread alloc] initWithBlock:^{
        [self installMissingLibraries];
    }];
    [thread1 start];
    
    /*
     * detect if XQuartz is installed
     */
    if (access(XQUARTZ_PATH, F_OK) != 0)
    {
        // XXX Fetch beta.xml from xquartz's site
        // XXX Read the XML file and get xquartz_download_url
        
        const char *xquartz_download_url = "https://dl.bintray.com/xquartz/downloads/XQuartz-2.7.11.dmg";
        
        __block
        BOOL installationSucceeded = false;
        
        //
        // Must start the Helper
        //
        CFErrorRef error = nil;
        if (!blessHelperWithLabel(kSMJOBBLESSHELPER_IDENTIFIER, &error))
        {
            NSLog(@"Failed to bless helper. Error: %@", (__bridge NSError *)error);
            showErrorAlertWithMessageForWindow(@"Failed to launch helper.", _window);
            [_progressIndicator stopAnimation:nil];
            [_doneButton setEnabled:YES];
            return;
        }
        
        xpc_connection_t connection = xpc_connection_create_mach_service(SMJOBBLESSHELPER_IDENTIFIER, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
        if (!connection)
        {
            NSLog(@"Failed to create XPC connection.");
            showErrorAlertWithMessageForWindow(@"Failed to create connection to helper.", _window);
            [_progressIndicator stopAnimation:nil];
            [_doneButton setEnabled:YES];
            return;
        }
        
        /* set the event handler */
        xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
            xpc_type_t type = xpc_get_type(event);
            
            if (type == XPC_TYPE_ERROR)
            {
                if (event == XPC_ERROR_CONNECTION_INVALID) {
                    // The client process on the other end of the connection has either
                    // crashed or cancelled the connection. After receiving this error,
                    // the connection is in an invalid state, and you do not need to
                    // call xpc_connection_cancel(). Just tear down any associated state
                    // here.
                    NSLog(@"CONNECTION_INVALID");
                } else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
                    // Handle per-connection termination cleanup.
                     NSLog(@"CONNECTION_IMMINENT");
                } else {
                     NSLog(@"Got unexpected (and unsupported) XPC ERROR");
                }
                
                if (!installationSucceeded)
                {
                    /*
                     * Show the user we failed!
                     */
                    xpc_connection_cancel(connection);
                    showErrorAlertWithMessageForWindow(@"Something went wrong during XQuartz installation.", self->_window);
                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       [self->_doneButton setEnabled:YES];
                                   });
                }
                else
                {
                    //
                    // Otherwise the errors are normal, and indicate termination of helper.
                    //
                }

            }
            else
            {
                /*
                 * We either got data from the Helper (stdout)
                 *  or we got the "I am done here..." message which
                 *  means we can continue with the rest here.
                 */
                
                /* get the message */
                const char* message = xpc_dictionary_get_string(event, "msg");
                
                if (strcmp(message, HELPER_FINISHED_MESSAGE) == 0)
                {
                    installationSucceeded = true;
                    dispatch_async(dispatch_get_main_queue(),
                                   ^{
                                       NSExtendedAlert *alert = [[NSExtendedAlert alloc] init];
                                       [alert setMessageText:@"Conky Finished Installing"];
                                       [alert runModalSheetForWindow:self->_window];
                                   
                                       [self->_progressIndicator stopAnimation:nil];
                                       [self->_doneButton setEnabled:YES];
                                   });
                }
                else
                {
                    [self writeToLog:[NSString stringWithFormat:@"%s\n", message]];
                }
            }
        });
        
        /* resume/start communication */
        xpc_connection_resume(connection);
        
        NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"InstallXQuartz" ofType:@"sh"];
        
        /*
         * send a initial message to trigger HELPER's event handler.
         * This is the one and only time we should send a message to the Helper
         *  for the sake of keeping the event handler simple.
         */
        xpc_object_t startupDictionary = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_string(startupDictionary, "url", xquartz_download_url);
        xpc_dictionary_set_string(startupDictionary, "scriptPath", [scriptPath UTF8String]);
        xpc_connection_send_message(connection, startupDictionary);
    }
    else
    {
        [_progressIndicator stopAnimation:nil];
        [_doneButton setEnabled:YES];
    }
    
    /*
     * Create symbolic link to install ConkyX to Applications
     */
    if (![fm createSymbolicLinkAtPath:@"/Applications/ConkyX.app" withDestinationPath:[[NSBundle mainBundle] pathForResource:@"ConkyX" ofType:@"app"] error:&error])
    {
        NSLog(@"Error creating symlink to Applications for ConkyX: \n\n%@", error);
        showErrorAlertWithMessageForWindow(@"Failed to install ConkyX.", _window);
    }
    
    /*
     * Create symbolic link to allow using from terminal
     */
    if (![fm createSymbolicLinkAtPath:@"/usr/local/bin/conky" withDestinationPath:@"/Applications/ConkyX.app/Contents/Resources/conky" error:&error])
    {
        NSLog(@"Error creating symbolic link to /usr/local/bin: %@", error);
        showErrorAlertWithMessageForWindow(@"Failed to create conky symbolic link.", _window);
    }
}

- (IBAction)doneButtonPressed:(id)sender
{
    [[self window] close];
}

@end
