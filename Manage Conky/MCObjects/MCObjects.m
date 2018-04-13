//
//  MCObjects.m
//  Manage Conky
//
//  Created by npyl on 13/04/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCObjects.h"

// defines
#define MC_PID_NOT_SET (-100)   /* pid not yet set */

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
    [res setThemeRC:themeRC];
    [res setConkyConfigs:configs];
    [res setArguments:args];
    [res setStartupDelay:startupDelay];
    [res setWallpaper:wallpaper];
    [res setCreator:creator];
    [res setSource:source];
    
    [res setPid:MC_PID_NOT_SET];
    return res;
}

+ (instancetype)themeRepresentationForPath:(NSString *)path
{
    NSString *themeRoot = path;
    NSString *themeRC = [NSString stringWithFormat:@"%@/%@.cmtheme", themeRoot, [themeRoot lastPathComponent]];
    NSString *MCThemeRC = [themeRoot stringByAppendingString:@"/themerc.plist"];
    BOOL useMCThemeRCFile = NO;
    
    /*
     * Information to be extracted from theme rc file
     */
    NSInteger startupDelay = 0;
    NSArray *conkyConfigs = nil;
    NSArray *arguments = nil;
    NSString *wallpaper = nil;
    NSString *creator = @"unknown";
    NSString *source = @"unknown";
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    /*
     * Check if themerc.plist exists which means we are using
     *  ManageConky type Themes; otherwise fallback to conky-manager
     *  compatibility Themes.
     */
    useMCThemeRCFile = [fm fileExistsAtPath:MCThemeRC];
    
    if (useMCThemeRCFile)
    {
        /*
         * Doing it the ManageConky way...
         */
        themeRC = MCThemeRC;
        
        NSDictionary *rc = [NSDictionary dictionaryWithContentsOfFile:themeRC];
        
        //startupDelay = [rc objectForKey:@"startupDelay"];
        conkyConfigs = [rc objectForKey:@"configs"];    // must be Array, not Dictionary because each arguments list corresponds to specific conkyConfig
        arguments = [rc objectForKey:@"args"];
        wallpaper = [rc objectForKey:@"wallpaper"];
        source = [rc objectForKey:@"source"];
        creator = [rc objectForKey:@"creator"];
    }
    else
    {
        /*
         * Doing it the conky-manager way...
         */
        
        // parse the file
        
        source = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/source.txt"] encoding:NSUTF8StringEncoding error:nil];
        creator = [NSString stringWithContentsOfFile:[themeRoot stringByAppendingString:@"/creator.txt"] encoding:NSUTF8StringEncoding error:nil];
    }
    
    /*
     * create theme representation
     */
    id res = [[self alloc] init];
    [res setThemeRC:themeRC];
    [res setConkyConfigs:conkyConfigs];
    [res setArguments:arguments];
    [res setStartupDelay:startupDelay];
    [res setWallpaper:wallpaper];
    [res setCreator:creator];
    [res setSource:source];
    
    [res setPid:MC_PID_NOT_SET];
    return res;
}

- (void)applyTheme
{
    NSLog(@"Applying theme...");
}
@end

@implementation MCWidget
+ (instancetype)widgetWithPid:(pid_t)pid andPath:(NSString *)path
{
    id res = [[self alloc] init];
    [res setPid:pid];
    [res setItemPath:path];
    return res;
}
@end
