//
//  ViewController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/09/2017.
//  Copyright © 2017 Nickolas Pylarinos. All rights reserved.
//

#import <unistd.h>
#import "MCObjects.h"
#import <Cocoa/Cocoa.h>
#import "MCConfigEditor.h"

typedef enum {
    widgetsThemesTableShowWidgets,
    widgetsThemesTableShowThemes,
} MCWidgetThemesTableShow;

@interface ViewController : NSViewController<NSTableViewDelegate, NSTableViewDataSource, NSSearchFieldDelegate>
{
    MCWidgetThemesTableShow whatToShow;
    NSMutableArray<MCTheme *> *themesArray;
    NSMutableArray<MCWidget *> *widgetsArray;

    NSPopover *previewPopover;
    
    MCConfigEditor *editorController;
    NSPopover *editorPopover;
}

@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSButton *toggleLoggerButton;
@property (weak) IBOutlet NSTableView *widgetsThemesTable;

/**
 * Functions for Main VC Table Manipulation
 * ===================================================
 * Some ManageConky classes use ViewController because
 * they need to manipulate the MAIN view controller's
 * widgets/themes table.
 */
- (void)fillWidgetsThemesArraysWithSearchPath:(NSString *)searchPath;
- (void)fillWidgetsThemesArrays;
- (void)emptyWidgetsThemesArrays;
- (void)updateWidgetsThemesArray;

/**
 * Functions for easy Widgets / Themes access
 * =====================================================
 * Some ManageConky classes use ViewController because
 * they leverage its advanced Widget/Themes manipulation
 * capabilities.
 */
- (void)createWidgetsArray;
- (NSMutableArray *)themes;
- (NSMutableArray *)widgets;
@end
