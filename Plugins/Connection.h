#import <Cordova/CDV.h>

@interface Connection : CDVPlugin <NSURLSessionDelegate>
- (void)send:(CDVInvokedUrlCommand*)command;
@end
