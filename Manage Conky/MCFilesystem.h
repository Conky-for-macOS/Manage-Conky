//
//  MCFilesystem.h
//  Manage Conky
//
//  Created by Nickolas Pylarinos on 08/08/2018.
//  Copyright © 2018 Nickolas Pylarinos. All rights reserved.
//

#ifndef MCFilesystem_h
#define MCFilesystem_h

#import <Cocoa/Cocoa.h>

/**
 * Return ManageConky directory path in ~/Library
 */
NSString *MCDirectory(void);

/**
 * Create ManageConky directory in ~/Library
 */
void createMCDirectory(void);

NSString* MCNormalise(NSString *path);

#endif /* MCFilesystem_h */
