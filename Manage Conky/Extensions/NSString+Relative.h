//
//  NSString+Relative.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 27/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Relative)

/**
 * isRelative
 *
 * Returns `YES` if string represents a relative path.
 */
- (BOOL)isRelative;

@end
