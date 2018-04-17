//
//  MCConfigEditor.h
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GeneralSheetController.h"

@interface MCConfigEditor : NSViewController<NSTextViewDelegate>

@property (unsafe_unretained) IBOutlet NSTextView *editorView;

- (void)loadConfig:(NSString *)config;
@end
