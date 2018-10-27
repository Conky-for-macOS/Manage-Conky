//
//  NSString+Relative.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 27/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "NSString+Relative.h"

@implementation NSString (Relative)

- (BOOL)isRelative
{
    return ([self characterAtIndex:0] != '/');
}

@end
