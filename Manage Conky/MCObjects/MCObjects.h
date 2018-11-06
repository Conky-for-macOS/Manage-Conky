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

/* defines */
#define MC_PID_NOT_SET (-100)   /* pid not yet set */

/*
 * Conky Basic Configuration Keys
 */
static NSString *kMCRunConkyAtStartupKey = @"runConkyAtStartup";
static NSString *kMCKeepAliveConkyKey = @"keepAlive";
static NSString *kMCConkyStartupDelayKey = @"startupDelay";
static NSString *kMCConkyConfigsLocationKey = @"configsLocation";
static NSString *kMCConkyAdditionalSearchPathsKey = @"additionalSearchPaths";
static NSString *kMCCanResizeWindow = @"CanResizeWindow";

/*
 * Conky ThemeRC (Plist) Keys
 */
static const NSString *kMCThemeStartupDelayKey = @"startupDelay";
static const NSString *kMCThemeConfigsKey = @"configs";
static const NSString *kMCThemeArgumentsKey = @"args";
static const NSString *kMCThemeWallpaperKey = @"wallpaper";
static const NSString *kMCThemeSourceKey = @"source";
static const NSString *kMCThemeCreatorKey = @"creator";
static const NSString *kMCThemeScalingKey = @"scaling";

/*
 * Misc Keys
 */
static const NSString *kMCOldWallpaperKey = @"MCOldWallpaper";

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

@class ViewController;

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
    ViewController *mainViewController; /* handle to main view controller */
}

+ (instancetype)sharedSettings;

/*
 * General Conky Settings
 * ======================
 */
- (void)setConkyRunsAtStartup:(BOOL)a;
- (BOOL)conkyRunsAtStartup;

- (void)setKeepAliveConky:(BOOL)a;
- (BOOL)keepAliveConky;

- (void)setConkyStartupDelay:(NSInteger)startupDelay;
- (NSInteger)conkyStartupDelay;

- (void)setConfigsLocation:(NSString *)a;
- (NSString *)configsLocation;
- (NSArray *)additionalSearchPaths;
- (void)addAdditionalSearchPath:(NSString *)path;
- (void)setAdditionalSearchPaths:(NSArray *)array;

- (void)setMainViewController:(ViewController *)vc;
- (ViewController *)mainViewController;

- (void)setCanResizeWindow:(BOOL)a;
- (BOOL)canResizeWindow;

/*
 * Logfile
 * =======
 */
- (void)setShouldLogToFile:(BOOL)a;
- (BOOL)shouldLogToFile;
- (void)setLogfile:(NSString *)logfile;
- (NSString *)logfile;

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
 * Vector of Windows -- Used for always knowing current window
 * ===========================================================
 * (push/pop/current)
 */
- (void)pushWindow:(NSWindow *)window;
- (void)popWindow;
- (NSWindow *)currentWindow;

/*
 * Mac Wallpaper Manipulation
 * ==========================
 */
/**
 * Returns current wallpaper used
 */
- (NSString *)wallpaper;
/**
 * Sets a record of the image used as current
 * wallpaper, soon to be replaced by MCTheme
 * wallpaper.
 */
- (void)setOldWallpaper:(NSString *)old;
/**
 * Returns path to the image used as wallpaper before
 * applying the current MCTheme.
 */
- (NSString *)oldWallpaper;
/**
 * Sets desktop wallpaper using image located in
 * `wallpaper` (path), with scaling options and
 * error message.
 */
- (BOOL)setWallpaper:(NSString *)wallpaper withScaling:(MCWallpaperScaling)scaling error:(NSError **)error;
/**
 * Returns `YES` if the wallpaper given is not used
 * by any of the User's MCThemes!
 */
- (BOOL)wallpaperIsNotFromMCTheme:(NSString *)wallpaper;

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

+ (instancetype)widgetWithPid:(pid_t)pid andRC:(NSString *)path;
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
