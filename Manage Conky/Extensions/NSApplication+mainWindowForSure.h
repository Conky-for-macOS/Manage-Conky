//
//  NSApplication+mainWindowForSure.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 27/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSApplication (mainWindowForSure)

/**
 * mainWindow
 *
 * This should OVERRIDE the default [NSApp mainWindow] method;
 * BUT WHY OVERRIDE it?
 *
 * Because (as stated by Apple) -mainWindow can return nil, for
 * example when mainWindow is hidden! We don't want that!
 */
- (NSWindow *)mainWindow;

@end
