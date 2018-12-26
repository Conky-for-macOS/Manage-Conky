//
//  Logger.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 17/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Logger.h"

#import "Shared.h"

#include <vector>
using namespace std;

static vector<NSTextView *> _textViews;
static BOOL _isOpen = NO;   // a public _isOpen property
static int _id = 0;

@implementation Logger

+ (id)logger
{
    static id res = nil;
    if (!res)
    {
        res = [[self alloc] init];
        //_textViews = [NSMutableArray array];
    }
    return res;
}

- (void)windowDidLoad
{
    [[super window] setTitle:[[super window].title stringByAppendingFormat:@" window %i", ++_id]];
    _textViews.push_back(self->_textView);
    _isOpen = YES;
}

- (void)addFilehandleForReading:(NSFileHandle *)fh
{
    /*
     * Setup Readibility Handler
     */
    [fh setReadabilityHandler:^(NSFileHandle *fileHandle) {
        NSData *data = [fileHandle availableData];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        for (NSTextView *_textView0 : _textViews)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _textView0.string = [_textView0.string stringByAppendingString:str];
            });
        }
    }];
    
    [fh acceptConnectionInBackgroundAndNotify];
}

- (BOOL)isOpen { return _isOpen; }

@end
