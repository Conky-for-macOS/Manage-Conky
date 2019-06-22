//
//  MCPluginAPI.h
//  MCPluginAPI
//
//  Created by Nickolas Pylarinos Stamatelatos on 19/06/2019.
//  Copyright © 2019 Nickolas Pylarinos. All rights reserved.
//

#import "MCPluginAPI.h"
#import "ZKSwizzle.h"

@interface MCSettings : NSObject
+ (instancetype)sharedInstance;
@end
@implementation MCSettings
+ (instancetype)sharedInstance {
    return ZKOrig(id);
}
@end

static MCSettings *settings = nil;

@implementation MCPlugin
// Hook Into MCSettings
// Use sharedInstance to get an instance of MCSettings

/*
 * This function secretly initialises the PluginAPI
 *
 * It needs to be:
 * a) hidden from the plugin maker (=> do not define it in Plugin.h)
 * b) known to MC's ViewController (=> implement it in Plugin.m and teach ViewController about it)
 */
- (void)start0 {
    NSLog(@"!start0!");
    
    // Hook Into MCSettings
    ZKSwizzle(self, MCSettings);
    
    // Get the handle to MC's settings for API-internal use
    settings = [MCSettings sharedInstance];
}

@end
