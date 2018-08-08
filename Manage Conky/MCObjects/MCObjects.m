//
//  MCObjects.m
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "Shared.h"  // createUserLaunchAgentsDirectory(), MCDirectory()
#import "MCObjects.h"
#import <Foundation/Foundation.h>
#import <AHLaunchCtl/AHLaunchCtl.h>

@implementation MCSettings
+ (instancetype)sharedInstance
{
    static id res = nil;
    if (!res)
        res = [[self alloc] init];
    return res;
}

- (void)setConkyRunsAtStartup:(BOOL)a
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:a]
                                              forKey:@"runConkyAtStartup"];
}

- (BOOL)conkyRunsAtStartup
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:@"runConkyAtStartup"] boolValue];
}

- (void)setConfigsLocation:(NSString *)a
{
    [[NSUserDefaults standardUserDefaults] setObject:a
                                              forKey:@"configsLocation"];
}

- (NSString *)configsLocation
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"configsLocation"];
}

- (void)installManageConkyFilesystem
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    /*
     * Create symbolic link to install ConkyX to Applications
     */
    if (![fm createSymbolicLinkAtPath:@"/Applications/ConkyX.app" withDestinationPath:[[NSBundle mainBundle] pathForResource:@"ConkyX" ofType:@"app"] error:&error])
    {
        NSLog(@"Error creating symlink to Applications for ConkyX: \n\n%@", error);
    }
    
    /*
     * Create symbolic link to allow using from terminal
     */
    if (![fm createSymbolicLinkAtPath:CONKY_SYMLINK withDestinationPath:@"/Applications/ConkyX.app/Contents/Resources/conky" error:&error])
    {
        NSLog(@"Error creating symbolic link to /usr/local/bin: %@", error);
    }
}

- (void)uninstallManageConkyFilesystem
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [fm removeItemAtPath:CONKYX error:&error];
    if (error) { NSLog(@"Error removing ConkyX: \n\n%@", error); }
    
    error = nil;
    
    [fm removeItemAtPath:CONKY_SYMLINK error:&error];
    if (error) { NSLog(@"Error removing symlink: \n\n%@", error); }
}

- (void)uninstallCompletelyManageConkyFilesystem
{
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [self uninstallManageConkyFilesystem];
    
    [fm removeItemAtPath:MANAGE_CONKY error:&error];
    if (error) { NSLog(@"Error removing Manage Conky: \n\n%@", error); }
}

@end

@implementation MCWidgetOrTheme
- (void)enable {}
- (void)reenable {}
- (void)kill {}
- (void)disable {}
- (BOOL)isEnabled { return YES; }

- (void)uninstall:(NSString *)path
{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[path stringByDeletingLastPathComponent] error:&error];
    
    if (error)
        NSLog(@"%@", error);
}

- (void)uninstall {}
- (void)configureMCSettingsHolder { MCSettingsHolder = [MCSettings sharedInstance]; }
@end

@implementation MCWidget
+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path
{
    NSString *widgetName = [[path lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    
    id res = [[self alloc] init];
    [res setPid:pid];
    [res setItemPath:path];
    [res setWidgetName:widgetName];
    [res setWidgetLabel: [NSString stringWithFormat:@"%@.%@", LAUNCH_AGENT_PREFIX, widgetName]];
    [res configureMCSettingsHolder];
    return res;
}

- (void)kill
{
    int stat_loc = 0;
    kill(_pid, SIGINT);
    waitpid(_pid, &stat_loc, WNOHANG);
    [self setPid:MC_PID_NOT_SET];
}

- (void)enable
{
    /*
     * itemPath must have the spaces replaced by '\'
     * Because bash is - well... bash! - and it won't
     * parse them correctly.  Also fix the '(' and ')'.
     */
    NSString *correctedItemPath = [_itemPath stringByReplacingOccurrencesOfString:@" "
                                                                       withString:@"\\ "];
    correctedItemPath = [correctedItemPath stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    correctedItemPath = [correctedItemPath stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    
    /*
     * IF conky is set to run at startup we must do LaunchAgent housekeeping...
     */
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        NSInteger startupDelay = [[[NSUserDefaults standardUserDefaults] objectForKey:@"startupDelay"] integerValue];
        BOOL keepAlive = [[[NSUserDefaults standardUserDefaults] objectForKey:@"keepAlive"] boolValue];

        /*
         * setup the LaunchAgent
         */
        createLaunchAgent(_widgetLabel,
                          @[CONKY_SYMLINK, @"-c", correctedItemPath],
                          keepAlive,
                          startupDelay,
                          [_itemPath stringByDeletingLastPathComponent],
                          nil);
    }
    else
    {
        NSString *cmd = [NSString stringWithFormat:@"%@ -c %@", CONKY_SYMLINK, correctedItemPath];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/bin/bash"];
        [task setArguments:@[@"-l",
                             @"-c",
                             cmd]];
        [task setCurrentDirectoryPath:[_itemPath stringByDeletingLastPathComponent]];
        [task setEnvironment:[NSProcessInfo processInfo].environment];          /*
                                                                                 * Some conky widgets like Conky-Vision
                                                                                 * (original: https://github.com/zagortenay333/conky-Vision)
                                                                                 * use external executables thus we need to
                                                                                 * provide the basic environment for them
                                                                                 * like environment-variables.
                                                                                 */
        [task launch];
        
        pid_t pid = [task processIdentifier];
        [self setPid:pid];
    }
}

/**
 * re-enable
 *
 * Restart widget
 */
- (void)reenable
{
    if (![MCSettingsHolder conkyRunsAtStartup])
    {
        [self kill];
        [self enable];
        
        /*
         Although we have a workaround for #29 we still can't rely on
         SIGUSR1 because it has some side-effects such as causing the
         Gotham Widget to be non-draggable.  If https://github.com/Conky-for-macOS/conky-for-macOS/issues/29
         gets a proper solution (e.g. the XDamage incompatibilities get
         fixed) this should be the optimal solution to restarting the
         widget:
         
        kill(_pid, SIGUSR1);
         */
    }
}

- (void)disable
{
    [self kill];
    
    /*
     * IF conky is set to run at startup we must do LaunchAgent housekeeping...
     */
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        removeLaunchAgent(_widgetLabel);
    }
}

- (BOOL)isEnabled
{
    /*
     * IF conky is set to run at startup we must do LaunchAgent housekeeping...
     */
    if ([MCSettingsHolder conkyRunsAtStartup])
    {
        return isLaunchAgentEnabled(_widgetLabel);
    }
    else return (_pid != MC_PID_NOT_SET) ? YES : NO;
}

- (void)uninstall
{
    [super uninstall:_itemPath];
}

@end

@implementation MCTheme
+ (instancetype)themeWithResourceFile:(NSString *)themeRC
                         conkyConfigs:(NSArray *)configs
                            arguments:(NSArray *)args
                         startupDelay:(NSInteger)startupDelay
                            wallpaper:(NSString *)wallpaper
                              creator:(NSString *)creator
                               source:(NSString *)source
                           andScaling:(MCWallpaperScaling)scaling;
{
    id res = [[self alloc] init];
    
    /*
     * General properties
     */
    [res setThemeRC:themeRC];
    [res setConkyConfigs:configs];
    [res setArguments:args];
    [res setStartupDelay:startupDelay];
    [res setWallpaper:wallpaper];
    [res setCreator:creator];
    [res setSource:source];
    [res setScaling:scaling];
    
    [res configureMCSettingsHolder];
    
    /*
     * themeName
     */
    [res setThemeName:[[themeRC stringByDeletingLastPathComponent] lastPathComponent]];
    
    /*
     * isEnabled?
     * Try accessing the Theme's lock
     */
    NSString *lock = [NSHomeDirectory() stringByAppendingFormat:@"/Library/ManageConky/%@.theme.lock", [res themeName]];
    [res setIsEnabled: (access([lock UTF8String], R_OK) == 0)];
    
    return res;
}

+ (instancetype)themeRepresentationForThemeRC:(NSString *)themeRC
{
    /*
     * Information to be extracted from theme rc file
     */
    NSInteger startupDelay = 0;
    NSArray *conkyConfigs = [NSArray array];
    NSArray *arguments = [NSArray array];
    NSString *wallpaper = nil;
    __block NSString *strScaling = nil;
    MCWallpaperScaling scaling = FillScreen;
    NSString *creator = @"unknown";
    NSString *source = @"unknown";
    
    macScalingKeys = @[@"FillScreen",
                       @"FitToScreen",
                       @"StretchToFillScreen",
                       @"Centre",
                       @"Tile",
                       ];
    
    legacyScalingKeys = @[@"",
                          @"",
                          @"",
                          @"",
                          @"",
                          ];
    
    /*
     * Is it modern or legacy theme?
     */
    BOOL useMCThemeRCFile = [[themeRC pathExtension] isEqualToString:@"plist"] ? YES : NO;
    
    if (useMCThemeRCFile)
    {
        /*
         * Doing it the ManageConky way...
         */
        NSDictionary *rc = [NSDictionary dictionaryWithContentsOfFile:themeRC];
        
        startupDelay = [[rc objectForKey:@"startupDelay"] integerValue];
        
        /* Try to standardize paths read first. */
        NSMutableArray *conkyConfigsUnstandardized = [rc valueForKey:@"configs"];   // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig

        for (NSUInteger i = 0; i < [conkyConfigsUnstandardized count]; i++)
        {
            conkyConfigsUnstandardized[i] = [conkyConfigsUnstandardized[i] stringByStandardizingPath];
        }
        
        /* then write them filtered */
        conkyConfigs = [conkyConfigsUnstandardized copy];

        arguments = [rc valueForKey:@"args"];  // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        wallpaper = [[rc objectForKey:@"wallpaper"] stringByExpandingTildeInPath];
        source = [rc objectForKey:@"source"];
        creator = [rc objectForKey:@"creator"];
        strScaling = [rc objectForKey:@"scaling"];
    }
    else
    {
        /*
         * Doing it the conky-manager way...
         */
        
        NSString *themeRoot = [themeRC stringByDeletingLastPathComponent];
        
        NSError *error = nil;
        NSMutableArray *lines = [NSMutableArray array];
        
        [[NSString stringWithContentsOfFile:themeRC
                                   encoding:NSUTF8StringEncoding
                                      error:&error] enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
            /* We need to avoid empty lines */
            if (![line isEqualToString:@""])
                [lines addObject:line];
        }];
        
        if ([lines count] == 0)
            return nil;
        
        /* pretty index */
        NSInteger i = [lines count] - 1;
        
        /*
         * Take scaling (last line)
         */
        strScaling = [[lines objectAtIndex:i] substringFromIndex:18];
        
        /*
         * Take wallpaper which is always the line before-last;
         */
        i -= 1;
        wallpaper = [[lines objectAtIndex:i] stringByExpandingTildeInPath];
        
        /*
         * Remove scaling & wallpaper;
         * Leave only configs inside
         */
        [lines removeLastObject];
        [lines removeLastObject];
        
        /*
         * Take configs
         */
        /* first expand tilde */
        for (int i = 0; i < [lines count]; i++)
        {
            [lines setObject:[[lines objectAtIndex:i] stringByExpandingTildeInPath] atIndexedSubscript:i];
        }
        conkyConfigs = lines;
        
        source = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/source.txt"] encoding:NSUTF8StringEncoding error:nil];
        if (!source)
            source = @"unknown";
        creator = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/creator.txt"] encoding:NSUTF8StringEncoding error:nil];
        if (!creator)
            creator = @"unknown";
    }
    
    /*
     * Lookup scaling string in keys
     */
    if ([macScalingKeys containsObject:strScaling])
    {
        scaling = [macScalingKeys indexOfObject:strScaling];
    }
    else if ([legacyScalingKeys containsObject:strScaling])
    {
        NSString *modernKey = [self scalingKeyConvertLegacyToModern:strScaling];
        scaling = [legacyScalingKeys indexOfObject:modernKey];
    }
    else
    {
        // oops; completely bad key passed from user
        // scaling = FillScreen by default
    }
    
    /*
     * create theme representation
     */
    return [self themeWithResourceFile:themeRC
                          conkyConfigs:conkyConfigs
                             arguments:arguments
                          startupDelay:startupDelay
                             wallpaper:wallpaper
                               creator:creator
                                source:source
                            andScaling:scaling];
}

/*
 * Method that converts a legacy-key (conky-manager) to a modern-mac key (ManageConky)
 */
+ (NSString *)scalingKeyConvertLegacyToModern:(NSString *)legacyKey
{
    return @"FillScreen";   // XXX actually write some code here...
}

- (BOOL)applyWallpaper:(NSString *)wallpaper withScaling:(MCWallpaperScaling)scaling error:(NSError **)error
{
    /*
     * based on https://github.com/sindresorhus/macos-wallpaper
     */
    
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSScreen *screen = [NSScreen mainScreen];
    NSMutableDictionary *so = [sw desktopImageOptionsForScreen:screen].mutableCopy;

    switch (scaling)
    {
        case FillScreen:
            [so setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
            [so setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
            break;
        case FitToScreen:
            [so setObject:[NSNumber numberWithInt:NSImageScaleProportionallyUpOrDown] forKey:NSWorkspaceDesktopImageScalingKey];
            [so setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
            break;
        case StretchToFillScreen:
            [so setObject:[NSNumber numberWithInt:NSImageScaleAxesIndependently] forKey:NSWorkspaceDesktopImageScalingKey];
            [so setObject:[NSNumber numberWithBool:YES] forKey:NSWorkspaceDesktopImageAllowClippingKey];
            break;
        case Centre:
            [so setObject:[NSNumber numberWithInt:NSImageScaleNone] forKey:NSWorkspaceDesktopImageScalingKey];
            [so setObject:[NSNumber numberWithBool:NO] forKey:NSWorkspaceDesktopImageAllowClippingKey];
            break;
        case Tile:
            // XXX what do we do here???
            break;
        case MAX_SCALING_KEYS:
        default:
            break;
    }
    
    return [sw setDesktopImageURL:[NSURL fileURLWithPath:wallpaper]
                        forScreen:screen
                          options:so
                            error:error];
}


/**
 * enable
 *
 * Applies this Theme to computer by:
 *  - applying conky config(s)
 *  - applying wallpaper
 *
 * supports two types of Themes:
 *  - original conky-manager Themes (plain files with minimal info) (backwards compatibility)
 *  - plist-based (support many parameters/features in a native macOS way)
 */
- (void)enable
{
    /**
     * We create a LaunchAgent foreach conky-config of the Theme and
     * a lock indicating that the theme is enabled on this user account.
     */

    /*
     * create required directories
     */
    createUserLaunchAgentsDirectory();
    createMCDirectory();
    
    /*
     * Create LaunchAgent foreach config
     */
    for (NSString *config in _conkyConfigs)
    {
        NSString *configName = [[config lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSString *label = [NSString stringWithFormat:@"org.npyl.ManageConky.Theme.%@", configName];
        NSString *workingDirectory = [config stringByDeletingLastPathComponent];
        const BOOL keepAlive = YES;
        NSError *error = nil;
        
        createLaunchAgent(label,
                          @[CONKY_SYMLINK, @"-c", config],
                          keepAlive,
                          _startupDelay,
                          workingDirectory,
                          error);
        
        if (error)
        {
            NSLog(@"applyTheme: Error creating agent: %@", error);
            return;
        }
    }
    
    /*
     * Apply wallpaper
     */
    NSError *err = nil;
    [self applyWallpaper:_wallpaper withScaling:_scaling error:&err];
    if (err)
    {
        NSLog(@"applyTheme: Failed to apply wallpaper with error: \n\n%@", err);
    }
    
    /*
     * Create a lock for theme
     */
    NSString *lock = [NSHomeDirectory() stringByAppendingFormat:@"/Library/ManageConky/%@.theme.lock", _themeName];
    
    [[NSFileManager defaultManager] createFileAtPath:lock
                                            contents:nil
                                          attributes:nil];
    
    _isEnabled = YES;
}

/**
 * re-enable
 *
 * Enable Theme BUT first check if already enabled and kill it
 * to achieve restart!
 */
- (void)reenable
{
    if ([self isEnabled])
        [self kill];
    [self enable];
}

- (void)disable
{
    for (NSString *config in _conkyConfigs)
    {
        NSString *configName = [[config lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        NSString *label = [NSString stringWithFormat:@"org.npyl.ManageConky.Theme.%@", configName];
        removeLaunchAgent(label);
    }
    
    /*
     * Delete the lock
     */
    NSString *lock = [NSHomeDirectory() stringByAppendingFormat:@"/Library/ManageConky/%@.theme.lock", _themeName];
    
    unlink([lock UTF8String]);
    
    _isEnabled = NO;
}

- (void)uninstall
{
    [super uninstall:_themeRC];
}

@end
