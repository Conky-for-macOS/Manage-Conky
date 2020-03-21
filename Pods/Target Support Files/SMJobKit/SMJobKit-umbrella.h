#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SMJClient.h"
#import "SMJClientUtility.h"
#import "SMJError.h"
#import "SMJErrorTypes.h"
#import "SMJobKit.h"

FOUNDATION_EXPORT double SMJobKitVersionNumber;
FOUNDATION_EXPORT const unsigned char SMJobKitVersionString[];

