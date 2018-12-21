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

- (void)launch0
{
    [self setStandardOutput:[NSPipe pipe]];
    [self setStandardError:[NSPipe pipe]];
    
    if ([[Logger logger] isOpen])
    {
        [[Logger logger] addFilehandleForReading:[[self standardOutput] fileHandleForReading]];
        [[Logger logger] addFilehandleForReading:[[self standardError] fileHandleForReading]];
    }

    [self launch];  // call original
}

@end
