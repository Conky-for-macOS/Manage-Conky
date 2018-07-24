//
//  SaveThemeSheetController.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 22/07/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "GeneralSheetController.h"

typedef enum : NSUInteger {
    FillScreen = 0,
    FitToScreen,
    StretchToFillScreen,
    Centre,
    Tile,
} MCWallpaperScaling;

@interface SaveThemeSheetController : NSWindowController<NSTableViewDelegate>
{
    NSUInteger propertiesFilledIn;  /* count of properties filled by user;
                                     * If he forgets one, prompt the user. */
#define MC_MAX_PROPERTIES   5   /* max properties to fill */
}

@property NSString *name;
@property NSString *wallpaper;
@property NSArray *conkyConfigs;
@property NSString *source;
@property NSString *creator;
@property MCWallpaperScaling scaling;

@property (weak) IBOutlet NSTextField *wallpaperPathLabel;

@property (strong) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *themeNameField;
@property (weak) IBOutlet NSPopUpButton *scalingPopUpButton;

- (id)initWithWindowNibName:(NSString *)nibName;

@end
