//
//  MCConfigEditor.m
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCConfigEditor.h"
#include "Shared.h"

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

        // I am not sure how to get proper NSRect
        // but surely this is a way to do it.
        NSTextField *dummyField = [NSTextField textFieldWithString:_conkyConfigContents];
        NSRect editorFieldRect = dummyField.bounds;

        _editorField = [[MGSFragariaView alloc] initWithFrame:editorFieldRect];

        // Lua is my city
        [_editorField setSyntaxDefinitionName:@"lua"];

        // set initial text
        [_editorField setString:_conkyConfigContents];

        // embed in our container - exception thrown if containerView is nil
        [self setView:_editorField];
    }
    return self;
}

- (void)viewWillDisappear
{
    NSError *error = nil;
    
    NSString *viewContents = [_editorField string];
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
