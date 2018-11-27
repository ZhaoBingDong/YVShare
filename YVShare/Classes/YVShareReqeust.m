//
//  YVShareReqeust.m
//  YVThirdPart
//
//  Created by dzb on 2018/3/24.
//

#import "YVShareReqeust.h"

@implementation YVShareReqeust

+ (void)get:(NSString *)urlPath completionHandler:(void (^)(id data, NSError *error))completionHandler
{
    
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlPath]];
	request.HTTPMethod = @"GET";
	NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id responseObject = nil;
        NSError *err = nil;
        if (data) {
            responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        }
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(responseObject, error);
            });
        }
	}];
	[task resume];
    
}

+ (void)get:(NSString *)urlPath params:(NSDictionary *)params completionHandler:(void (^)(id, NSError *))completionHandler
{
	
    NSMutableString *paramsString = @"?".mutableCopy;
    for (NSString *key in params.allKeys) {
        [paramsString appendFormat:@"%@=%@&",key,params[key]];
    }
	NSString *url = [NSString stringWithFormat:@"%@%@",urlPath,paramsString];
	//url = [url stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
	url 		  = [url stringByRemovingPercentEncoding];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	request.HTTPMethod = @"GET";
	
	NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
		id responseObject = nil;
		NSError *err = nil;
		if (data) {
			responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
		}
		if (completionHandler) {
			dispatch_async(dispatch_get_main_queue(), ^{
				completionHandler(responseObject, error);
			});
		}
	}];
	[task resume];
	
}


@end
