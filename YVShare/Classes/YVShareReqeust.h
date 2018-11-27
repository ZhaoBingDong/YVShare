//
//  YVShareReqeust.h
//  YVThirdPart
//
//  Created by dzb on 2018/3/24.
//

#import <Foundation/Foundation.h>

@interface YVShareReqeust : NSObject

+ (void) get:(NSString *)urlPath completionHandler:(void (^)(id data, NSError *error))completionHandler;

+ (void) get:(NSString *)urlPath params:(NSDictionary *)params completionHandler:(void (^)(id, NSError *))completionHandler;


@end
