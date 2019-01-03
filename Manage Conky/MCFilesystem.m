//
//  MCFilesystem.m
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/08/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#import "MCFilesystem.h"

/**
 * MCDirectory
 *
 * Easily retrieve path to ManageConky directory in ~/Library
 */
NSString *MCDirectory(void)
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/ManageConky"];
}

/**
 * createMCDirectory
 *
 * Helper function to create ~/Library/ManageConky directory
 */
void createMCDirectory(void)
{
    NSError *error;
    [[NSFileManager defaultManager] createDirectoryAtPath:MCDirectory() withIntermediateDirectories:NO attributes:nil error:&error];
    if (error)
    {
        NSLog(@"Failed to create ManageConky directory with error: \n\n%@", error);
    }
}

/**
 * MCNormalise
 *
 * path must have the spaces replaced by '\'
 * Because bash is - well... bash! - and it won't
 * parse them correctly.  Also fix the '(' and ')'.
 */
NSString* MCNormalise(NSString *path)
{
    NSString *correctedPath = [path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
    correctedPath = [correctedPath stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
    correctedPath = [correctedPath stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
    return correctedPath;
}
