//
//  main.c
//  ManageConkySMJobBlessHelper
//
//  Created by npyl on 24/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <syslog.h>
#import <xpc/xpc.h>
#import "Shared.h"

@interface SMJobBlessHelper : NSObject
{
    xpc_connection_t connection_handle;
    xpc_connection_t service;
}
@end
@implementation SMJobBlessHelper

- (void)CLEANUP_SMJOBBLESS_REQUIRED_ITEMS_FROM_FILESYSTEM
{
    ///
    /// Must cleanup generated files...
    ///
}

- (void)SEND_FINISHED_MESSAGE_AND_WAIT_FOR_REPLY:(xpc_object_t)event
{
    xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);

    xpc_object_t finishMessage = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(finishMessage, "msg", "I am done here...");
    xpc_connection_send_message_with_reply(remote, finishMessage, dispatch_get_main_queue(), ^(xpc_object_t  _Nonnull object)
                                           {
                                               /*
                                                * DO-NOTHING, being here means ManageConky got our message
                                                *   that we are quiting so we are now free to invalidate connection!
                                                */
                                               NSLog(@"I am finished here... Quitting...");
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
        
        xpc_object_t msg = xpc_dictionary_create(NULL, NULL, 0);
        xpc_dictionary_set_string(msg, "msg", [str UTF8String]);
        xpc_connection_send_message(connection_handle, msg);
    }
};

- (void) __XPC_Peer_Event_Handler:(xpc_connection_t)connection withEvent:(xpc_object_t)event
{
    xpc_type_t type = xpc_get_type(event);
    
    if (type == XPC_TYPE_ERROR) {
        if (event == XPC_ERROR_CONNECTION_INVALID) {
            // The client process on the other end of the connection has either
            // crashed or cancelled the connection. After receiving this error,
            // the connection is in an invalid state, and you do not need to
            // call xpc_connection_cancel(). Just tear down any associated state
            // here.
            syslog(LOG_NOTICE, "CONNECTION_INVALID");
        } else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
            // Handle per-connection termination cleanup.
            syslog(LOG_NOTICE, "CONNECTION_IMMINENT");
        } else {
            syslog(LOG_NOTICE, "Got unexpected (and unsupported) XPC ERROR");
        }
        
        xpc_connection_cancel(connection);
        exit(EXIT_FAILURE);
    }
    else
    {
        syslog(LOG_NOTICE, "HERE! Eventually...");
        
        connection_handle = connection;
        
        /*
         * Get the initial message from Manage Conky
         * which is the url to download XQuartz
         */
        const char *xquartz_download_url = xpc_dictionary_get_string(event, "url");
        NSString *xquartzDownloadUrl = [NSString stringWithUTF8String:xquartz_download_url];
        if (!xquartzDownloadUrl)
            exit(EXIT_FAILURE);
        
        const char *script_path = xpc_dictionary_get_string(event, "scriptPath");
        NSString *scriptPath = [NSString stringWithUTF8String:script_path];
        if (!scriptPath)
            exit(EXIT_FAILURE);
        
        NSLog(@"GOT MESSAGE = %s", xquartz_download_url);
        NSLog(@"GOT SCRIPT LOCATION = %@", scriptPath);
        
        NSPipe *outputPipe = [[NSPipe alloc] init];
        NSPipe *errorPipe = [[NSPipe alloc] init];
        
        NSTask *script = [[NSTask alloc] init];
        [script setLaunchPath:@"/bin/sh"];
        [script setArguments:@[scriptPath, xquartzDownloadUrl]];
        [script setStandardOutput:outputPipe];
        [script setStandardError:errorPipe];
        
        NSFileHandle *outputHandle = [outputPipe fileHandleForReading];
        NSFileHandle *errorHandle = [errorPipe fileHandleForReading];
        
        [outputHandle waitForDataInBackgroundAndNotify];
        [errorHandle waitForDataInBackgroundAndNotify];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:outputHandle];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedData:) name:NSFileHandleDataAvailableNotification object:errorHandle];
        
        [script setTerminationHandler:^(NSTask * _Nonnull script) {
            /*
             * Tell ManageConky that we are done here... and wait for his reply
             *  before invalidating the connection and causing false positives for him...
             */
            [self SEND_FINISHED_MESSAGE_AND_WAIT_FOR_REPLY:event];
            [self CLEANUP_SMJOBBLESS_REQUIRED_ITEMS_FROM_FILESYSTEM];
            xpc_connection_cancel(connection);
            exit([script terminationStatus]);
        }];
        
        [script launch];
        [script waitUntilExit];
    }
}

- (void) __XPC_Connection_Handler:(xpc_connection_t)connection
{
    xpc_connection_set_event_handler(connection, ^(xpc_object_t event)
                                     {
                                         [self __XPC_Peer_Event_Handler:connection withEvent:event];
                                     });
    
    xpc_connection_resume(connection);
}

- (void)dispatchMain
{
    dispatch_main();
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        service = xpc_connection_create_mach_service(SMJOBBLESSHELPER_IDENTIFIER,
                                                                      dispatch_get_main_queue(),
                                                                      XPC_CONNECTION_MACH_SERVICE_LISTENER);
        if (!service)
        {
            syslog(LOG_NOTICE, "Failed to create service.");
            exit(EXIT_FAILURE);
        }
        
        xpc_connection_set_event_handler(service, ^(xpc_object_t connection)
                                         {
                                             [self __XPC_Connection_Handler:connection];
                                         });
        xpc_connection_resume(service);
    }
    return self;
}

@end

int main(int argc, const char *argv[])
{
    SMJobBlessHelper *helper = [[SMJobBlessHelper alloc] init];
    if (!helper)
        return EXIT_FAILURE;
    
    [helper dispatchMain];
    
    return EXIT_SUCCESS;
}
