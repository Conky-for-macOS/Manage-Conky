//
//  MCObjects.h
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#ifndef MCObjects_h
#define MCObjects_h

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger
{
    FillScreen = 0,
    FitToScreen,
    StretchToFillScreen,
    Centre,
    Tile,
    
    MAX_SCALING_KEYS,    /* used as a counter of Wallpaper Scaling keys */
}
MCWallpaperScaling;

static NSArray *macScalingKeys;

static const char *cMacScalingKeys[] = {
    "FillScreen",
    "FitToScreen",
    "StretchToFillScreen",
    "Centre",
    "Tile",
};

/* defines */
#define MC_PID_NOT_SET (-100)   /* pid not yet set */

/**
 * MCSettings
 *
 * ManageConky's settings class
 * Used to provide global access to ManageConky settings
 * amongst many parts of the program!
 */
@interface MCSettings : NSObject
{
    NSMutableArray *windowVector;
}

+ (instancetype)sharedInstance;

//
// Special getters and setters
//
- (void)setConkyRunsAtStartup:(BOOL)a;
- (BOOL)conkyRunsAtStartup;

- (void)setConfigsLocation:(NSString *)a;
- (NSString *)configsLocation;
- (NSArray *)additionalSearchPaths;
- (void)addAdditionalSearchPath:(NSString *)path;

/**
 * installManageConkyFilesystem
 *
 * Installs the basic files required for Manage Conky
 * to operate.  (eg. ConkyX, symbolic link)
 */
- (void)installManageConkyFilesystem;

/**
 * uninstallManageConkyFilesystem
 *
 * Uninstall everything that `installManageConkyFilesystem`
 * installed but keep ManageConky.app at /Applications
 */
- (void)uninstallManageConkyFilesystem;

/**
 * uninstallManageConkyFilesystem
 *
 * Uninstall everything that `installManageConkyFilesystem`
 * including ManageConky.app.
 */
- (void)uninstallCompletelyManageConkyFilesystem;

/*
 * Vector of Windows -- Always keep a record of current
 * window by maintaining a vector of windows (provide push/pop/current)
 */
- (void)pushWindow:(NSWindow *)window;
- (void)popWindow;
- (NSWindow *)currentWindow;
@end

//
// WIDGETS / THEMES SECTION
//

/**
 * MCWidgetOrTheme
 *
 * Abstract object upon which MCWidget and MCTheme are based!
 */
@interface MCWidgetOrTheme : NSObject
{
    MCSettings *MCSettingsHolder;
}

@property NSString *realName;   /* un-normalised name */

- (void)enable;
- (void)reenable;
- (void)kill;
- (void)disable;
- (BOOL)isEnabled;
- (void)uninstall:(NSString *)path;
- (void)uninstall;

- (void)configureMCSettingsHolder;
@end

/**
 * MCWidget
 *
 * ManageConky Widget representation.
 */
@interface MCWidget : MCWidgetOrTheme

@property pid_t pid;            /* pid */
@property NSString *itemPath;   /* conky *.conf path */
@property NSString *widgetName; /* widget's name */
@property NSString *widgetLabel;    /* label for LaunchAgent */

+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path;
@end

/**
 * MCTheme
 *
 * Representation of a ManageConky Theme.
 * Fully backwards compatible with conky-manager Themes (.cmtheme).
 */
@interface MCTheme : MCWidgetOrTheme

@property NSString *themeName;  /* theme name */
@property NSString *themeRC;    /* resource file (.plist or .cmtheme) */
@property NSInteger startupDelay;   /* startup delay */
@property NSArray *conkyConfigs;    /* conky configs */
@property NSArray *arguments;   /* arguments for conky */
@property NSString *wallpaper;  /* wallpaper used by theme */
@property MCWallpaperScaling scaling;   /* wallpaper scaling */

@property NSString *creator;    /* creator of theme */
@property NSString *source;     /* source of theme */

@property BOOL isEnabled;    /* a LaunchAgent for it exists */

/**
 * Set properties of MCTheme object just by getting the values for the
 *  General ones.  Also, set the Not-General ones.
 *
 *  ATTENTION: This function should be called by other `instancetype` init functions
 *   in order to set the not-general properties.
 */
+ (instancetype)themeWithResourceFile:(NSString *)themeRC
                         conkyConfigs:(NSArray *)configs
                            arguments:(NSArray *)args
                         startupDelay:(NSInteger)startupDelay
                            wallpaper:(NSString *)wallpaper
                              creator:(NSString *)creator
                               source:(NSString *)source
                           andScaling:(MCWallpaperScaling)scaling;

/**
 * Parse a theme resource-file from a path (themeRC) and create an MCTheme object.
 * Supports both modern ManageConky Themes and legacy conky-manager Themes.
 */
+ (instancetype)themeRepresentationForThemeRC:(NSString *)themeRC;
@end

#endif /* MCObjects_h */
