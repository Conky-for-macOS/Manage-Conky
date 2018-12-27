//
//  MCTask.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 19/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCTask.h"

#import "../Logger.h"
#import "../MCObjects/MCObjects.h"

@implementation NSTask (MCTask)

- (void)launchLoggableWithWidgetUniqueID:(NSUInteger)uniqueID
{
    if ([[MCSettings sharedSettings] logsWidgets])
    {
        [self setStandardOutput:[NSPipe pipe]];
        [self setStandardError:[NSPipe pipe]];
        
        [[Logger logger] addFilehandleForReading:[[self standardOutput] fileHandleForReading] forWidgetWithUniqueID:uniqueID];
        [[Logger logger] addFilehandleForReading:[[self standardError] fileHandleForReading] forWidgetWithUniqueID:uniqueID];
    }

    [self launch];  // call original
}

@end
