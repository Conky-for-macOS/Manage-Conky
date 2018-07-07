//
//  MCObjects.m
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects.h"
#import "Shared.h"  // createUserLaunchAgentsDirectory(), MCDirectory()
#import <Foundation/Foundation.h>
#import <AHLaunchCtl/AHLaunchCtl.h>

/* defines */
#define CONKYX              @"/Applications/ConkyX.app"
#define MANAGE_CONKY        @"/Applications/Manage Conky.app"
#define CONKY_SYMLINK       @"/usr/local/bin/conky"
#define LAUNCH_AGENT_PREFIX @"org.npyl.ManageConky.Widget"

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
                          @[CONKY_SYMLINK, @"-c", _itemPath],
                          keepAlive,
                          startupDelay,
                          [_itemPath stringByDeletingLastPathComponent]);
        
        // xxx error checking
    }
    else
    {
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:CONKY_SYMLINK];
        [task setArguments:@[@"-c", _itemPath]];
        [task setCurrentDirectoryPath:[_itemPath stringByDeletingLastPathComponent]];
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
         Until #29 has been fixed for conky-for-macOS our best
         way of doing this is killing and restarting conky
         
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
        // xxx error checking
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
        // XXX error checking
    }
    else return (_pid != MC_PID_NOT_SET) ? YES : NO;
}
@end

@implementation MCTheme
+ (instancetype)themeWithResourceFile:(NSString *)themeRC
                         conkyConfigs:(NSArray *)configs
                            arguments:(NSArray *)args
                         startupDelay:(NSInteger)startupDelay
                            wallpaper:(NSString *)wallpaper
                              creator:(NSString *)creator
                            andSource:(NSString *)source;
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
    
    [res configureMCSettingsHolder];
    
    /*
     * themeName
     */
    [res setThemeName:[[themeRC stringByDeletingLastPathComponent] lastPathComponent]];
    
    /*
     * isEnabled?
     * Set isEnabled property by attempting to access the Theme's equivalent LaunchAgent plist
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
    __block NSString *scaling = nil;
    NSString *creator = @"unknown";
    NSString *source = @"unknown";
    
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
        conkyConfigs = [rc valueForKey:@"configs"];    // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        arguments = [rc valueForKey:@"args"];  // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        wallpaper = [[rc objectForKey:@"wallpaper"] stringByExpandingTildeInPath];
        source = [rc objectForKey:@"source"];
        creator = [rc objectForKey:@"creator"];
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
        scaling = [[lines objectAtIndex:i] substringFromIndex:18];
        
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
     * create theme representation
     */
    return [self themeWithResourceFile:themeRC
                          conkyConfigs:conkyConfigs
                             arguments:arguments
                          startupDelay:startupDelay
                             wallpaper:wallpaper
                               creator:creator
                             andSource:source];
}

- (BOOL)apply_wallpaper:(NSString *)wallpaper error:(NSError **)error
{
    /*
     * based on https://github.com/sindresorhus/macos-wallpaper
     */
    
    NSWorkspace *sw = [NSWorkspace sharedWorkspace];
    NSScreen *screen = [NSScreen mainScreen];
    NSMutableDictionary *so = [[sw desktopImageOptionsForScreen:screen] mutableCopy];
    
    return [sw setDesktopImageURL:[NSURL fileURLWithPath:wallpaper]
                        forScreen:screen
                          options:so
                            error:error];
}


/**
 * enable
 *
 * Applies this Theme to computer by:
 *  - applying conky config
 *  - applying wallpaper
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
        NSString *label = [NSString stringWithFormat:@"org.npyl.ManageConky.Theme.%@", config];
        NSString *workingDirectory = [config stringByDeletingLastPathComponent];
        
        createLaunchAgent(label,
                          @[CONKY_SYMLINK, @"-c", config],
                          YES,
                          _startupDelay,
                          workingDirectory);
    }
    
    /*
     * Apply wallpaper
     */
    NSError *err = nil;
    [self apply_wallpaper:_wallpaper error:&err];
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
    
    // xxx error checking
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

- (void)kill
{
}

- (void)disable
{
    for (NSString *config in _conkyConfigs)
    {
        NSString *label = [NSString stringWithFormat:@"org.npyl.ManageConky.Theme.%@", config];
        removeLaunchAgent(label);
    }
    
    /*
     * Delete the lock
     */
    NSString *lock = [NSHomeDirectory() stringByAppendingFormat:@"/Library/ManageConky/%@.theme.lock", _themeName];
    
    unlink([lock UTF8String]);
    
    _isEnabled = NO;
}
@end
