//
//  SaveWidgetSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Fragaria/Fragaria.h>

NS_ASSUME_NONNULL_BEGIN

@interface SaveWidgetSheetController : NSWindowController

@property (strong) IBOutlet MGSFragariaView *scriptView;
@property (strong) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *widgetSourceField;
@property (weak) IBOutlet NSTextField *widgetCreatorField;

- (id)initWithWindowNibName:(NSString *)nibName;

@end

NS_ASSUME_NONNULL_END
