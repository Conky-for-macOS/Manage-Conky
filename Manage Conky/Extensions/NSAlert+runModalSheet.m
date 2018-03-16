//
//  NSAlert+runModalSheet.m
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 11/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "NSAlert+runModalSheet.h"

@implementation NSExtendedAlert
- (NSModalResponse)runModalSheetForWindow:(NSWindow *)window
{
    [self beginSheetModalForWindow:window completionHandler:^(NSModalResponse returnCode)
     {
         [NSApp stopModalWithCode:returnCode];
     }];
    NSModalResponse modalCode = [NSApp runModalForWindow:[self window]];
    return modalCode;
}
@end
