//
//  SaveWidgetSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "SaveWidgetSheetController.h"

@implementation SaveWidgetSheetController

- (id)initWithWindowNibName:(NSString *)nibName;
{
    self = [super initWithWindowNibName:nibName];
    if (self)
    {
        [_scriptView setSyntaxDefinitionName:@"lua"];
    }
    return self;
}

- (IBAction)cancelButton:(id)sender
{
    [self.window close];
}

- (IBAction)saveButton:(id)sender
{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:@"Choose Widget's Location"];
    [sp setNameFieldLabel:@"Widget's Name"];
    NSModalResponse res = [sp runModal];
    
    if (res == NSModalResponseOK)
    {
        NSString *widgetDirectory = sp.URL.path;
        NSString *widgetConfig = [widgetDirectory stringByAppendingPathComponent:sp.nameFieldStringValue];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
//        NSLog(@"%@", widgetDirectory);
//        NSLog(@"%@", widgetConfig);
        
        [fm createDirectoryAtPath:widgetDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        /* save conf */
        [fm createFileAtPath:widgetConfig
                    contents:[self->_scriptView.string dataUsingEncoding:NSUTF8StringEncoding]
                  attributes:nil];
        
        [self.window close];
    }
}

@end
