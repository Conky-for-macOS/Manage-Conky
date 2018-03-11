//
//  NSAlert+runModalSheet.m
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 11/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "NSAlert+runModalSheet.h"

@implementation NSAlertExtension
- (NSInteger)runModalSheetForWindow:(NSWindow *)aWindow
{
    [self beginSheetModalForWindow:aWindow completionHandler:^(NSModalResponse returnCode)
     {
         [NSApp stopModalWithCode:returnCode];
     }];
    NSInteger modalCode = [NSApp runModalForWindow:[self window]];
    return modalCode;
}
@end
