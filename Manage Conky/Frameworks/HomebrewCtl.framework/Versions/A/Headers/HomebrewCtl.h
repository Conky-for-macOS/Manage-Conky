//
//  HomebrewCtl.h
//  HomebrewCtl
//
//  Created by npyl on 03/06/2018.
//  Copyright © 2018 npyl. All rights reserved.
//

/*
 *  Installing Homebrew (https://brew.sh) at custom location is not officially supported;
 *  though this framework has the goal to "put some pressure" to the team to support it
 *  and to provide a cool API for Homebrew-control from Objective-C.
 */

#import <Cocoa/Cocoa.h>

#define HOMEBREW_CTL_API_VER    0.3

/* Cool Defines */
#define DEFAULT_HOMEBREW_PREFIX @"/usr/local"

/* HomebrewCtl errors */
#define HOMEBREWCTL_ERROR_DOMAIN @"HomebrewCtlErrorDomain"

#define kHCMalformedPathPassedMsg @"Path has incorrect structure; Please check your `location` argument"
#define kHCInstallFailedInstallationAlreadyExistsMsg @"A Homebrew installation already exists at location specified"    
#define kHCFailedToCreateHomebrewDicectoryErrorMsg @"Failed to create Homebrew directory inside the location you provided"  /* e.g. mkdir problem */


enum HomebrewCtlErrors {
    kHCMalformedPathPassed = -1,
    kHCInstallFailedInstallationAlreadyExists = -2,
    kHCFailedToUpdate = -3,
    kHCFailedToUpgrade = -4,
};


@interface HomebrewCtl : NSObject
{
    NSThread *th;
}

+ (instancetype)init;
+ (instancetype)controller;

@property BOOL overwriteExistingInstallation;
@property BOOL installationFinished;
@property BOOL needsUpgrade;

/**
 *  Download and install Homebrew in a custom location
 *
 *  @note Doesn't add new Homebrew installation to $PATH
 *  @note Aborts if installation already present at `location`; Please set `overwriteExistingInstallation` accordingly.
 *
 *  @warning BEWARE; If you choose to overwrite your installation will be completely removed; you will loose all your software.
 *
 *  @param location Location to install Homebrew
 *  @param error Error
 *  @return Returns `YES` on success, or `NO` on failure.
 */
- (BOOL)installHomebrewAt:(NSString *)location error:(NSError **)error;
- (void)installHomebrewAt:(NSString *)location completionHandler:(void (^)(NSInteger terminationStatus, NSError *error))completionHandler;

/**
 *  Uninstall a Homebrew installation
 *
 *  @note Removes caches and logs by default
 *  @param location Location of Homebrew installation
 */
- (BOOL)uninstallHomebrewAt:(NSString *)location error:(NSError **)error;

/**
 *  Update a Homebrew installation
 *
 *  @param location Location of Homebrew installation
 */
- (void)updateHomebrewAt:(NSString *)location;

/**
 *  Upgrade a Homebrew installation
 *
 *  @param location Location of Homebrew installation
 */
- (void)upgradeHomebrewAt:(NSString *)location;

/**
 *  Check if a Homebrew installation exists at a location
 *
 *  @param location The containing directory of the Homebrew installation
 *  @return `YES` if it exists, or `NO` if it doesn't.
 */
- (BOOL)installationExistsAt:(NSString *)location;

- (BOOL)installLibraries:(NSArray *)arr at:(NSString *)location;

- (void)addBINToPATHForInstallation:(NSString *)location;

- (void)waitUntilFinished;

@end

@interface DefaultHomebrewCtl : HomebrewCtl

- (BOOL)installHomebrew:(NSError **)error;
- (void)installHomebrewWithCompletionHandler:(void (^)(NSInteger terminationStatus, NSError *error))completionHandler;
- (BOOL)uninstallHomebrew:(NSError **)error;
- (void)updateHomebrew;
- (void)upgradeHomebrew;
- (BOOL)installationExists;
- (void)addBINToPATH;

@end
