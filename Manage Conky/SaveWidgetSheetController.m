//
//  SaveWidgetSheetController.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 24/09/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "SaveWidgetSheetController.h"

#import "Shared.h"
#import "ViewController.h"
#import "MCObjects/MCObjects.h"

@implementation SaveWidgetSheetController

- (void)awakeFromNib
{
    MC_RUN_ONLY_ONCE({
        resourcesLocations = [NSMutableArray array];
        [_scriptView setSyntaxDefinitionName:@"lua"];
    });
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
    [op setMessage:@"Choose Preview Image"];
    [op setAllowedFileTypes:@[@"png", @"jpg", @"jpeg", @"tiff"]];
    
    if ([op runModal] == NSModalResponseOK)
    {
        self->previewLocation = op.URL;
    }
}

- (IBAction)addResources:(id)sender
{
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:YES];
    [op setPrompt:@"Add"];
    
    if ([op runModal] == NSModalResponseOK)
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
    
    if ([sp runModal] == NSModalResponseOK)
    {
        NSString *widgetDirectory = sp.URL.path;
        NSString *parentDirectory = [widgetDirectory stringByDeletingLastPathComponent];
        NSString *widgetConfig = [widgetDirectory stringByAppendingPathComponent:widgetDirectory.lastPathComponent];
        NSString *widgetSource = [widgetDirectory stringByAppendingPathComponent:@"source.txt"];
        NSString *widgetCreator = [widgetDirectory stringByAppendingPathComponent:@"creator.txt"];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSError *error = nil;
        
        /*
         * Does this location belong to our `searchPaths`?
         */
        MCSettings *mcsettings = [MCSettings sharedSettings];
        if (
            ![[mcsettings additionalSearchPaths] containsObject:parentDirectory] &&
            ![[mcsettings configsLocation] isEqualToString:parentDirectory])
        {
            /* prompt user to add this to search paths */
            NSAlert *addSearchPath = [[NSAlert alloc] init];
            [addSearchPath setMessageText:@"Would you like to add this location to your search paths?"];
            [addSearchPath setAlertStyle:NSAlertStyleCritical];
            [addSearchPath addButtonWithTitle:@"Yes"];
            [addSearchPath addButtonWithTitle:@"No"];
            
            if ([addSearchPath runModal] == NSAlertFirstButtonReturn)
                [mcsettings addAdditionalSearchPath:parentDirectory];
            
            NSLog(@"Additional Search Locations: %@", [mcsettings additionalSearchPaths]);
        }
        
        /* delete any previous versions */
        [fm removeItemAtPath:widgetDirectory error:nil];
        
        /* create widget directory */
        [fm createDirectoryAtPath:widgetDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        if (error)
        {
            MCError(&error);
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
        if (previewLocation)
            if (![fm copyItemAtPath:previewLocation.path toPath:[widgetDirectory stringByAppendingPathComponent:[previewLocation.path lastPathComponent]] error:&error])
                MCError(&error);
        
        /* copy resources */
        for (NSURL *resource in resourcesLocations)
        {
            [fm copyItemAtPath:resource.path toPath:[widgetDirectory stringByAppendingPathComponent:[resource.path lastPathComponent]] error:&error];
            if (error)
            {
                MCError(&error);
            }
        }
        
        /* open widget's directory */
        [[NSWorkspace sharedWorkspace] openFile:widgetDirectory];

        /* refresh List of Widgets/Themes */
        [[[MCSettings sharedSettings] mainViewController] updateWidgetsThemesArray];
        
        [_delegate didSaveWidget];
    }
    else
    {
        [_delegate didNotSaveWidget];
    }
}

@end
