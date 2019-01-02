//
//  SaveThemeSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "SaveWidgetSheetController.h"
#import "MCObjects/MCObjects.h"

enum {
    MC_SAVETHEME_MODE_JUST_SELECT,
};

@interface SaveThemeSheetController : GeneralSheetController<NSTableViewDelegate, NSTableViewDataSource, SaveWidgetSheetControllerDelegate>
{
    NSMutableArray *fromListWidgets;
    NSMutableArray *fromDirectoryWidgets;
    NSMutableArray *searchDirectories;
}

@property NSString *name;
@property NSString *preview;
@property NSString *wallpaper;
@property NSMutableArray<NSString *> *conkyConfigs;
@property NSMutableArray<NSString *> *conkyConfigsPaths;
@property NSString *source;
@property NSString *creator;
@property MCWallpaperScaling scaling;

@property BOOL relative;    /* keep wallpaper path relative or not? */

@property (weak) IBOutlet NSTextField *themeNameField;
@property (weak) IBOutlet NSTextField *themeCreatorField;
@property (weak) IBOutlet NSTextField *themeSourceField;
@property (weak) IBOutlet NSPopUpButton *scalingPopUpButton;
@property (weak) IBOutlet NSTextField *wallpaperPathLabel;

/* secondary ui controls */
@property (weak) IBOutlet NSTextField *themeNameLabel;
@property (weak) IBOutlet NSTextField *themeCreatorLabel;
@property (weak) IBOutlet NSTextField *themeSourceLabel;
@property (weak) IBOutlet NSBox *horizontalLineOne;
@property (weak) IBOutlet NSBox *horizontalLineTwo;

@property (weak) IBOutlet NSTableView *widgetsTableView;

@end
