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

- (void)launchLoggableWithWidgetName:(NSString *)widgetName
{
    [self setStandardOutput:[NSPipe pipe]];
    [self setStandardError:[NSPipe pipe]];
    
    if ([[Logger logger] isOpen])
    {
        NSLog(@"adding fh for %@", widgetName);
        
        [[Logger logger] addFilehandleForReading:[[self standardOutput] fileHandleForReading] forWidgetWithName:widgetName];
        [[Logger logger] addFilehandleForReading:[[self standardError] fileHandleForReading] forWidgetWithName:widgetName];
    }

    [self launch];  // call original
}

@end
