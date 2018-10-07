//
//  SaveWidgetSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "SaveWidgetSheetController.h"

@implementation SaveWidgetSheetController

- (void)awakeFromNib
{
    static BOOL beenHereAgain = NO;
    if (beenHereAgain) { return; }
    beenHereAgain = YES;

    resourcesLocations = [NSMutableArray array];
    [_scriptView setSyntaxDefinitionName:@"lua"];
}

- (IBAction)clearButton:(id)sender
{
    _scriptView.string = @"";
    _widgetCreatorField.stringValue = @"";
    _widgetSourceField.stringValue = @"";
    [resourcesLocations removeAllObjects];
    previewLocation = [NSURL URLWithString:@""];
}

- (IBAction)addPreview:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    [op setPrompt:@"Add"];
    [op setAllowedFileTypes:@[@"png", @"jpg", @"jpeg", @"tiff"]];
    NSModalResponse res = [op runModal];

    if (res == NSModalResponseOK)
    {
        self->previewLocation = op.URL;
    }
}

- (IBAction)addResources:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setPrompt:@"Add"];
    NSModalResponse res = [op runModal];
    
    if (res == NSModalResponseOK)
    {
        for (NSURL *url in [op URLs])
        {
            [self->resourcesLocations addObject:url];
        }
    }
}

- (IBAction)saveButton:(id)sender
{
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:@"Choose Widget's Location"];
    [sp setNameFieldLabel:@"Widget's Name"];
    [sp setPrompt:@"Create"];
    NSModalResponse res = [sp runModal];
    
    if (res == NSModalResponseOK)
    {
        NSString *widgetDirectory = sp.URL.path;
        NSString *widgetConfig = [widgetDirectory stringByAppendingPathComponent:widgetDirectory.lastPathComponent];
        NSString *widgetSource = [widgetDirectory stringByAppendingPathComponent:@"source.txt"];
        NSString *widgetCreator = [widgetDirectory stringByAppendingPathComponent:@"creator.txt"];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        /* delete any previous versions */
        [fm removeItemAtPath:widgetDirectory error:nil];

        /* create widget directory */
        [fm createDirectoryAtPath:widgetDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        if (error)
        {
            NSLog(@"%@", error);
            return;
        }
        
        /* save conf */
        [fm createFileAtPath:widgetConfig
                    contents:[self->_scriptView.string dataUsingEncoding:NSUTF8StringEncoding]
                  attributes:nil];
        /* save source */
        [fm createFileAtPath:widgetSource
                    contents:[_widgetSourceField.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                  attributes:nil];
        /* save creator */
        [fm createFileAtPath:widgetCreator
                    contents:[_widgetCreatorField.stringValue dataUsingEncoding:NSUTF8StringEncoding]
                  attributes:nil];

        /* copy preview */
        [fm copyItemAtPath:previewLocation.path toPath:widgetDirectory error:&error];
        if (error)
        {
            NSLog(@"%@", error);
        }
        
        /* copy resources */
        for (NSURL *resource in resourcesLocations)
        {
            [fm copyItemAtPath:resource.path toPath:widgetDirectory error:&error];
            if (error)
            {
                NSLog(@"%@", error);
            }
        }
        
        /* open widget's directory */
        [[NSWorkspace sharedWorkspace] openFile:widgetDirectory];
    }
}

@end
