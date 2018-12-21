//
//  Logger.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 17/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Logger.h"

#import "Shared.h"

@implementation Logger

static BOOL _isOpen = NO;
static int _id = 0;

+ (id)logger
{
    static id res = nil;
    if (!res)
        res = [[self alloc] init];
    return res;
}

- (void)windowDidLoad
{
    [[super window] setTitle:[[super window].title stringByAppendingFormat:@" %i", ++_id]];
    _isOpen = YES;
}

- (void)addFilehandleForReading:(NSFileHandle *)fh
{
    NSLog(@"Adding fh: %@", fh);

    /*
     * Setup Readibility Handler
     */
    [fh setReadabilityHandler:^(NSFileHandle *fileHandle) {
        NSData *data = [fileHandle availableData];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

//        NSLog(@"%@", str);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_textView.string = [self->_textView.string stringByAppendingString:str];
        });
        
//        [fileHandle acceptConnectionInBackgroundAndNotify];
    }];
    
    [fh acceptConnectionInBackgroundAndNotify];
}

- (BOOL)isOpen { return _isOpen; }

@end
