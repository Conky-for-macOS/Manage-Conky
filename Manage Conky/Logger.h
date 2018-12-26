//
//  Logger.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 17/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"

@interface LoggerEntity : NSObject
@property NSString *widgetName;
@property NSTextView *textView;
@end

@interface Logger : GeneralSheetController<NSWindowDelegate>

@property NSString *widgetName;

@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSButton *closeButton;

+ (id)logger;

- (void)addFilehandleForReading:(NSFileHandle *)fh forWidgetWithName:(NSString *)widgetName;

- (BOOL)isOpen;

@end
