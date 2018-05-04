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

/**
 * MCSettings
 *
 * ManageConky's settings class
 * Used to provide global access to ManageConky settings
 * amongst many parts of the program!
 */
@interface MCSettings : NSObject
@property BOOL conkyRunsAtStartup;  /* yes or no? */
@end

/**
 * MCSettingsHolder
 *
 * Single MCSettings object to provide access to ManageConky settings
 * through any part of the program!
 */
static MCSettings *MCSettingsHolder;

//
// WIDGETS / THEMES SECTION
//

/**
 * MCWidgetOrTheme
 *
 * Abstract object upon which MCWidget and MCTheme are based!
 */
@interface MCWidgetOrTheme : NSObject
- (void)enable;
- (void)reenable;
- (void)kill;
- (void)disable;
- (BOOL)isEnabled;
@end

/**
 * MCWidget
 *
 * ManageConky Widget representation.
 */
@interface MCWidget : MCWidgetOrTheme

@property pid_t pid;            /* pid */
@property NSString *itemPath;   /* conky *.conf path */

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
                            andSource:(NSString *)source;

/**
 * Parse a theme resource-file from a path (themeRC) and create an MCTheme object.
 * Supports both modern ManageConky Themes and legacy conky-manager Themes.
 */
+ (instancetype)themeRepresentationForThemeRC:(NSString *)themeRC;
@end

#endif /* MCObjects_h */
