
#import "Connection.h"


@implementation Connection

- (void)send:(CDVInvokedUrlCommand*)command{
    [self.commandDelegate runInBackground:^{
        NSLog(@"%@", @"Connection.send");
        
        //settings for call. You may want to modify these settings. It would be smarter to
        // pass in the type of call this will be.
        NSString* type = @"POST";
        NSNumber* num = [[NSNumber alloc] initWithInt:2500];
        
        
        NSString* postData = [command.arguments objectAtIndex:2];
        NSDictionary *tmpDictionary = [NSJSONSerialization JSONObjectWithData:[postData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        NSMutableDictionary *resultsDictionary = [[NSMutableDictionary alloc] initWithDictionary:tmpDictionary];
        [resultsDictionary setValue:type forKeyPath:@"type"];
        [resultsDictionary setValue:num forKeyPath:@"timeout"];
        
        [self sendData:resultsDictionary completion:^(NSMutableDictionary *responseDic) {
            CDVPluginResult* pluginResult = nil;
            
            if([responseDic objectForKey:@"error"])
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: NULL];
            }else{
                NSError *error;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:responseDic options:NSJSONWritingPrettyPrinted error:&error];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }];
}

#pragma mark NSURLSessionDelegate implementation

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}


-(void) sendData:(NSDictionary*)resultsDic  completion:(void (^)(NSMutableDictionary *))completion {
    //settings
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 10;
    sessionConfig.timeoutIntervalForResource = 10;
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: sessionConfig delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    NSMutableURLRequest * urlRequest;
    
    if([resultsDic objectForKey:@"url"]){
        urlRequest = [NSMutableURLRequest requestWithURL:[[NSURL alloc]initWithString:[resultsDic objectForKey:@"url"]]];
    }
    
    [urlRequest setHTTPMethod: [resultsDic objectForKey:@"type"]];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [urlRequest setTimeoutInterval:(int)[resultsDic objectForKey:@"timeout"]];
    [urlRequest setHTTPBody:[[resultsDic objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask * dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                           
                                                           NSError *err;
                                                           NSMutableDictionary* results = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                                                           if(error){
                                                               [results setObject:error forKey:@"error"];
                                                           }
                                                           completion(results);
                                                       }];
    [dataTask resume];
}
@end
