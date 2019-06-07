//
//  MCConfigEditor.m
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCConfigEditor.h"

#import "MCObjects/MCObjects.h"

@implementation MCConfigEditor

- (IBAction)openDocs:(id)sender {
}

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
            MCError(&error);
            return nil;
        }
        
        int w = [NSImage imageNamed:NSImageNameInfo].size.width;
        int h = [NSImage imageNamed:NSImageNameInfo].size.height;

        NSButton *docs = [[NSButton alloc] init];
        [docs setImage:[NSImage imageNamed:NSImageNameInfo]];

        // I am not sure how to get proper NSRect
        // but surely this is a way to do it.
        NSTextField *dummyField = [NSTextField textFieldWithString:_conkyConfigContents];
        NSRect editorFieldRect = dummyField.bounds;

        _editorField = [[MGSFragariaView alloc] initWithFrame:editorFieldRect];
        [docs setFrame:NSMakeRect(0, 0, w, h)];
//        [docs setKeyEquivalent:]  //TODO
        [docs setAction:@selector(openDocs:)];
        
        [_editorField addSubview:docs];
        
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
        MCError(&error, @"Error applying changes to config");
    }
}

@end
