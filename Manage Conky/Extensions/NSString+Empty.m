//
//  NSString+NSString_Empty.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos Stamatelatos on 13/10/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "NSString+Empty.h"

@implementation NSString (Empty)

- (BOOL)empty
{
    return [self isEqualToString:@""];
}

@end
