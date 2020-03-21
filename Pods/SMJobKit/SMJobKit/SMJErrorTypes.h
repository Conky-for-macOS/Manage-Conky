#import <Foundation/Foundation.h>

typedef NS_ENUM(unsigned int, SMJErrorCode) {
  
  // A failure when referencing a bundle that doesn't exist (or bad perms)
  SMJErrorCodeBundleNotFound = 1000,
  // A failure when trying to get the SecStaticCode for a bundle, but it is unsigned
  SMJErrorCodeUnsignedBundle = 1001,
  // Unknown failure when calling SecStaticCodeCreateWithPath
  SMJErrorCodeBadBundleSecurity = 1002,
  // Unknown failure when calling SecCodeCopySigningInformation for a bundle
  SMJErrorCodeBadBundleCodeSigningDictionary = 1003,
  
  // Failure when calling SMJobBless
  SMJErrorCodeUnableToBless = 1010,
  
  // Authorization was denied by the system when asking a user for authorization
  SMJErrorCodeAuthorizationDenied = 1020,
  // The user canceled a prompt for authorization
  SMJErrorCodeAuthorizationCanceled = 1021,
  // Unable to prompt the user (interaction disallowed)
  SMJErrorCodeAuthorizationInteractionNotAllowed = 1022,
  // Unknown failure when prompting the user for authorization
  SMJErrorCodeAuthorizationFailed = 1023,
  
};
