//
//  MCConfigEditor.h
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GeneralSheetController.h"

@interface MCConfigEditor : NSViewController

@property NSString *conkyConfig;
@property NSString *conkyConfigContents;

@property NSTextField *editorField;

- (instancetype)initWithConfig:(NSString *)config;

@end
