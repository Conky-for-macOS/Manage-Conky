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

/* guards */
static BOOL canGoBack = NO;
static BOOL canOpenDocs = YES;

- (IBAction)openDocs:(id)sender
{
    if (!canOpenDocs)
        return;
    
    static NSString * docs = nil;

    if (!docs)
    {
        docs = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/brndnmtthws/conky/master/doc/variables.xml"]
                                        encoding:NSUTF8StringEncoding
                                           error:nil];
    }

    _editorField.string = docs;
    _editorField.syntaxDefinitionName = @"html";
    
    canGoBack = YES;
    canOpenDocs = NO;
}

- (IBAction)goBack:(id)sender {
    if (!canGoBack)
        return;

    _editorField.string = _conkyConfigContents;
    _editorField.syntaxDefinitionName = @"lua";
    
    canGoBack = NO;
    canOpenDocs = YES;
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

        // Setup Docs Button
        NSButton *docs = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, w, h)];
        [docs setImage:[NSImage imageNamed:NSImageNameInfo]];
        [docs setKeyEquivalentModifierMask:NSControlKeyMask];
        [docs setKeyEquivalent:@"i"];
        [docs setAction:@selector(openDocs:)];
        
        // Setup Back Button
        NSButton *back = [[NSButton alloc] initWithFrame:NSMakeRect(0, 40, w, h)];
        [back setImage:[NSImage imageNamed:NSImageNameGoBackTemplate]];
        [back setKeyEquivalentModifierMask:NSControlKeyMask];
        [back setKeyEquivalent:@"["];
        [back setAction:@selector(goBack:)];

        // I am not sure how to get proper NSRect
        // but surely this is a way to do it.
        NSTextField *dummyField = [NSTextField textFieldWithString:_conkyConfigContents];
        NSRect editorFieldRect = dummyField.bounds;

        _editorField = [[MGSFragariaView alloc] initWithFrame:editorFieldRect];

        // Add Docs Button
        [_editorField addSubview:docs];

        // Add Back Button
        [_editorField addSubview:back];
        
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
