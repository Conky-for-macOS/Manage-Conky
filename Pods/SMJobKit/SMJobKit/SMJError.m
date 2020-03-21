#import "SMJError.h"

@implementation SMJError

+ (NSError*) errorWithCode:(NSInteger)code message:(NSString*)message
{
  NSDictionary* userInfo = @{NSLocalizedDescriptionKey: message};
  
  return [self errorWithDomain:@"SMJobKit" code:code userInfo:userInfo];
}

@end
