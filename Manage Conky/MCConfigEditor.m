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

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [_editorView toggleAutomaticDashSubstitution:self];
    [_editorView toggleAutomaticTextCompletion:self];
    [_editorView toggleAutomaticTextReplacement:self];
    [_editorView toggleSmartInsertDelete:self];
    [_editorView toggleAutomaticQuoteSubstitution:self];
    [_editorView toggleAutomaticSpellingCorrection:self];
}

- (void)loadConfig:(NSString *)config
{
    NSError *error = nil;
    NSString *conkyConfigContents = [NSString stringWithContentsOfFile:config
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
    [_editorView setString:conkyConfigContents];
}

@end
