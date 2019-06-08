//
//  MCConfigEditor.h
//  Manage Conky
//
//  Created by npyl on 17/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>
#import "GeneralSheetController.h"

@interface MCConfigEditor : NSViewController
@property NSString *conkyConfig;
@property NSString *conkyConfigContents;
@property NSString *editorString;

@property MGSFragariaView *editorField;

- (instancetype)initWithConfig:(NSString *)config;
@end
