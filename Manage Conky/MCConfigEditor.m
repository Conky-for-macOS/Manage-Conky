//
//  MCConfigEditor.m
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCConfigEditor.h"

@interface MCConfigEditor ()

@end

@implementation MCConfigEditor

- (instancetype)initWithConfig:(NSString *)config
{
    self = [super init];
    if (self)
    {
        NSError *error = nil;
        
        _conkyConfig = config;
        _conkyConfigContents = [NSString stringWithContentsOfFile:config
                                                         encoding:NSUTF8StringEncoding
                                                            error:&error];

        if (error)
        {
            NSLog(@"%@", error);
            return nil;
        }
        
        _editorField = [NSTextField textFieldWithString:_conkyConfigContents];
        
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        NSClipView *clipView = [[NSClipView alloc] init];
        
        [clipView setDocumentView:_editorField];
        [scrollView setContentView:clipView];
        [self setView:scrollView];
    }
    return self;
}

- (void)viewWillDisappear
{
    NSError *error = nil;
    
    NSString *viewContents = [_editorField stringValue];
    [viewContents writeToFile:_conkyConfig
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:&error];
    if (error)
    {
        NSLog(@"Error applying changes to config: \n\n%@", error);
    }
}

@end
