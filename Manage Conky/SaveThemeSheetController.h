//
//  SaveThemeSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects/MCObjects.h"
#import "GeneralSheetController.h"


@interface SaveThemeSheetController : GeneralSheetController<NSTableViewDelegate, NSTableViewDataSource>
{
    NSUInteger propertiesFilledIn;  /* count of properties filled by user;
                                     * If he forgets one, prompt the user. */
#define MC_MAX_PROPERTIES   4   /* max properties to fill */
}

@property NSString *name;
@property NSString *wallpaper;
@property NSMutableArray<NSString *> *conkyConfigs;
@property NSString *source;
@property NSString *creator;
@property MCWallpaperScaling scaling;

@property BOOL relative;    /* keep wallpaper path relative or not? */

@property (weak) IBOutlet NSTextField *themeNameField;
@property (weak) IBOutlet NSTextField *themeCreatorField;
@property (weak) IBOutlet NSTextField *themeSourceField;

@property (weak) IBOutlet NSTableView *widgetsTableView;

@property (weak) IBOutlet NSPopUpButton *scalingPopUpButton;

@property (weak) IBOutlet NSTextField *wallpaperPathLabel;

@end
