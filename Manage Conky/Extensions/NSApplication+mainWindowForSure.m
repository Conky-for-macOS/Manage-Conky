//
//  NSApplication+mainWindowForSure.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 27/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "NSApplication+mainWindowForSure.h"

@implementation NSApplication (mainWindowForSure)

- (NSWindow *)mainWindow
{
    /*
     * Getting the list of the app's windows and choosing
     * the first should always return the mainWindow,
     * avoiding a nil, hidden or not!
     */
    return [[NSApp windows] firstObject];
}

@end
