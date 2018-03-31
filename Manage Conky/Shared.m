//
//  Shared.m
//  Manage Conky
//
//  Created by npyl on 31/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Shared.h"

void showErrorAlertWithMessageForWindow(NSString* msg, NSWindow* window)
{
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       NSExtendedAlert *failed = [[NSExtendedAlert alloc] init];
                       [failed setMessageText:@"Error!"];
                       [failed setInformativeText:msg];
                       [failed setAlertStyle:NSAlertStyleCritical];
                       [failed runModalSheetForWindow:window];
                   });
}
