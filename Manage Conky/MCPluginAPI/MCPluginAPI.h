//
//  MCPlugin.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 28/12/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for MCPluginAPI.
FOUNDATION_EXPORT double MCPluginAPIVersionNumber;

//! Project version string for MCPluginAPI.
FOUNDATION_EXPORT const unsigned char MCPluginAPIVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MCPluginAPI/PublicHeader.h>

@interface MCPlugin : NSObject
- (void)start;
@end
