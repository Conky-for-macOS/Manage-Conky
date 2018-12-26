//
//  MCTask.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 19/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCTask.h"

#import "../Logger.h"

@implementation NSTask (MCTask)

- (void)launchForWidgetWithName:(NSString *)widgetName
{
    [self setStandardOutput:[NSPipe pipe]];
    [self setStandardError:[NSPipe pipe]];
    
    if ([[Logger logger] isOpen])
    {
        [[Logger logger] addFilehandleForReading:[[self standardOutput] fileHandleForReading] forWidget:widgetName];
        [[Logger logger] addFilehandleForReading:[[self standardError] fileHandleForReading] forWidget:widgetName];
    }

    [self launch];  // call original
}

@end
