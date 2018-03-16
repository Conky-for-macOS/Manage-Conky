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
 * Provide extensions such as present a sheet with the ability to wait until completed.
 */
@interface NSExtendedAlert : NSAlert

/**
 * Show an alert-sheet with the ability to wait until its completion.
 *  Remember, the normal alert-sheet apple provides, shows up but doesn't wait until finished.
 *  Instead, application code executes normally even with the sheet waiting for buttons to be clicked.
 *
 * Taken from https://stackoverflow.com/questions/604768/wait-for-nsalert-beginsheetmodalforwindow
 */
- (NSModalResponse)runModalSheetForWindow:(NSWindow *)window;

@end

#endif /* NSAlert_runModalSheet_h */
