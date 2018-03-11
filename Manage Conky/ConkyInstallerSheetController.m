//
//  ConkyInstallerSheetController.m
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 02/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "ConkyInstallerSheetController.h"

#import "PFMoveApplication.h"
#import "NSAlert+runModalSheet.h"
#import <Foundation/NSFileManager.h>

#define MANAGE_CONKY_PATH "/Applications/Manage Conky.app"
#define HOMEBREW_PATH "/usr/local/bin/brew"
#define XQUARTZ_PATH  "/usr/X11"


@implementation ConkyInstallerSheetController

- (void)receivedData:(NSNotification*)notif
{
    NSFileHandle *fh = [notif object];
    NSData *data = [fh availableData];
    if (data.length > 0)
    {
        /* if data is found, re-register for more data (and print) */
        [fh waitForDataInBackgroundAndNotify];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            _logField.stringValue = [_logField.stringValue stringByAppendingString:str];
        });
    }
};

- (void)beginInstalling
{
    [_progressIndicator startAnimation:nil];
    
    /*
     * detect if Homebrew is installed
     */
    if (access(HOMEBREW_PATH, F_OK) != 0)
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://brew.sh"]];
        
        NSAlertExtension *hbalert = [[NSAlertExtension alloc] init];
        [hbalert setMessageText:@"Homebrew missing"];
        [hbalert setInformativeText:@"Install Homebrew first using the link I opened in the browser.\nOnce you install click OK to continue"];
        [hbalert setAlertStyle:NSAlertStyleCritical];
        [hbalert runModalSheetForWindow:_window];
    }
    
    /*
     * detect if XQuartz is installed
     */
    if (access(XQUARTZ_PATH, F_OK) != 0)
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.xquartz.org"]];
        
        NSAlertExtension *xqalert = [[NSAlertExtension alloc] init];
        [xqalert setMessageText:@"XQuartz is missing"];
        [xqalert setInformativeText:@"Install XQuartz first using the link I opened in the browser.\nOnce you install click OK to continue"];
        [xqalert setAlertStyle:NSAlertStyleCritical];
        [xqalert runModalSheetForWindow:_window];
    }
    
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
    
    NSFileHandle *outputHandle = [outputPipe fileHandleForReading],
    *errorHandle = [errorPipe fileHandleForReading];
    
    [outputHandle waitForDataInBackgroundAndNotify];
    [errorHandle waitForDataInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:outputHandle];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:errorHandle];
    
    [script setTerminationHandler:^(NSTask *task) {
        
        dispatch_async(dispatch_get_main_queue(),
        ^{
           [_progressIndicator stopAnimation:nil];
           
           NSAlert *alert = [[NSAlert alloc] init];
           [alert setMessageText:@"Conky Finished Installing"];
           [alert beginSheetModalForWindow:_window completionHandler:^(NSModalResponse returnCode)
            {
                NSError *error = nil;
                NSFileManager *fm = [[NSFileManager alloc] init];
                
                if (![fm createSymbolicLinkAtPath:@"/usr/local/bin/conky" withDestinationPath:@"/Applications/ConkyX.app/Contents/Resources/conky" error:&error])
                {
                    NSLog(@"Error creating symbolic link to /usr/local/bin: %@", error);
                }
                
                [_doneButton setEnabled:YES];
            }];
        });
    }];
    
    /*
     * run the installer script
     */
    [script launch];
}

- (IBAction)doneButtonPressed:(id)sender
{
    [[self window] close];
}

@end
