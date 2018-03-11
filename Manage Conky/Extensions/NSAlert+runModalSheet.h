//
//  NSAlert+runModalSheet.h
//  Manage Conky
//
//  Created by Nikolas Pylarinos on 11/03/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#ifndef NSAlert_runModalSheet_h
#define NSAlert_runModalSheet_h

#import <Cocoa/Cocoa.h>

/**
 * WOW! Taken from https://stackoverflow.com/questions/604768/wait-for-nsalert-beginsheetmodalforwindow
 */
@interface NSAlertExtension : NSAlert

- (NSInteger)runModalSheetForWindow:(NSWindow *)aWindow;

@end

#endif /* NSAlert_runModalSheet_h */
