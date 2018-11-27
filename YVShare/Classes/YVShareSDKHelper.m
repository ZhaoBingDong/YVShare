//
//  YVShareSDKHelper.m
//  YVPin
//
//  Created by dzb on 2017/11/30.
//  Copyright © 2017年 大兵布莱恩特. All rights reserved.
//

#import "OpenShare.h"
#import "OpenShare+QQ.h"
#import "YVShareReqeust.h"
#import "OpenShare+Weibo.h"
#import "OpenShare+Weixin.h"
#import "OpenShare+Alipay.h"
#import "YVShareSDKHelper.h"
#include <CommonCrypto/CommonHMAC.h>
#include <CommonCrypto/CommonDigest.h>

@interface YVShareSDKHelper ()

@property (nonatomic,copy) YVThirdPlatformLoginResponseState loginCompletionBlock;
@property (nonatomic,copy) YVThirdPlatformShareResponseState shareCompletionBlock;
@property (nonatomic,strong) YVThirdUser *authorizationUser;

@end

@implementation YVShareSDKHelper

@dynamic shareHelper;
@dynamic installWeChat;
@dynamic installWeibo;
@dynamic installQQ;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static YVShareSDKHelper *_helper;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _helper = [super allocWithZone:zone];
    });
    return _helper;
}

+ (YVShareSDKHelper *)shareHelper {
    return [[super alloc] init];
}

- (void)registerActivePlatforms {
    
    if (self.SSQQ) {
        [OpenShare connectQQWithAppId:self.SSQQ.appId];
    }
    if (self.SSSina) {
        [OpenShare connectWeiboWithAppKey:self.SSSina.appKey
                                appSecret:self.SSSina.appSecret
                              redirectURI:self.SSSina.appRediretUri];
    }
    if (self.SSWechat) {
        [OpenShare connectWeixinWithAppId:self.SSWechat.appId miniAppId:self.SSWechat.appSecret];
    }
    
}

/**
 处理程序通过URL启动第三方应用时传递的数据
 
 需要在 application:openURL:sourceApplication:annotation:或者application:handleOpenURL中调用
 @param url 启动第三方应用的URL
 */
- (BOOL)handleOpenURL:(NSURL *)url {
    ///支付宝回调
    if ([[url absoluteString] rangeOfString:@"//safepay/"].location != NSNotFound) {
        return [OpenShare Alipay_handleOpenURL:url];
    } else {
        return [OpenShare handleOpenURL:url];
    }
}

/**
 获取用户信息
 
 @param platformType 第三方平台类型车
 @param statusChange 获取用户信息状态发生改变
 */
+ (void) getUserInfo:(YVThirdPlatformType)platformType
      onStateChanged:(YVThirdPlatformLoginResponseState)statusChange {
    
    YVShareSDKHelper.shareHelper.loginCompletionBlock = statusChange;
    ///微博登录授权
    if (platformType == YVThirdPlatformTypeWeibo) {
        [YVShareSDKHelper ssoSinaPlatform];
    } else if (platformType == YVThirdPlatformTypeQQ) { //QQ登录
        [YVShareSDKHelper ssoQQPlatformAuth];
    } else if (platformType == YVThirdPlatformTypeWeChat) { //微信登录
        [YVShareSDKHelper ssoWechatPlatform];
    }
    YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateBegin, nil, nil);
    
}

#pragma mark - 新浪微博授权

+ (BOOL)installWeibo {
    return [OpenShare isWeiboInstalled];
}

/**
 SSO获取新浪微博授权信息
 */
+ (void) ssoSinaPlatform {
    
    __weak YVShareSDKHelper *shareHelper = [YVShareSDKHelper shareHelper];
    if (![YVShareSDKHelper installQQ]) {
        YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"未安装新浪微博,无法登陆" code:500 userInfo:nil]);
        return;
    }
    
    [OpenShare WeiboAuth:@"all" redirectURI:shareHelper.SSSina.appRediretUri Success:^(NSDictionary *message) {
        
        NSString *url                  = @"https://api.weibo.com/2/users/show.json";
        NSMutableDictionary *params  = [NSMutableDictionary dictionary];
        [params setObject:shareHelper.SSSina.appKey forKey:@"source"];
        [params setObject:message[@"accessToken"] forKey:@"access_token"];
        [params setObject: message[@"userID"] forKey:@"uid"];
        
        [YVShareReqeust get:url params:params completionHandler:^(NSDictionary *data, NSError *error) {
            NSMutableDictionary *dict = data.mutableCopy;
            [dict addEntriesFromDictionary:message];
            
#ifdef DEBUG
            NSLog(@"data:%@", dict);
            NSLog(@"error:%@", error);
#endif
            
            if (error || !dict) {
                
                if (shareHelper.loginCompletionBlock)
                    shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"微博获取个人资料失败" code:1 userInfo:nil]);
                
            } else {
                
                NSString *access_token                        = dict[@"accessToken"];
                NSString *icon                                   = dict[@"avatar_large"];
                NSString *gender                             = dict[@"gender"];
                NSString *nickname                            = dict[@"name"];
                NSString *openId                            = dict[@"requestID"];
                
                shareHelper.authorizationUser                = [[YVThirdUser alloc] init];
                shareHelper.authorizationUser.platformType  = YVThirdPlatformTypeWeibo;
                shareHelper.authorizationUser.icon             = icon;
                shareHelper.authorizationUser.nickname        = nickname;
                shareHelper.authorizationUser.gender         = [gender isEqualToString:@"m"] ? 1 : ([gender isEqualToString:@"f"] ? 2 : 0) ;
                shareHelper.authorizationUser.token            = access_token;
                shareHelper.authorizationUser.uid            = openId;
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateSuccess, shareHelper.authorizationUser, NULL);
                
            }
            
        }];
        
    } Fail:^(NSDictionary *message, NSError *error) {
        
        if (error) {
            NSInteger errorCode = error.code;
            if (errorCode == -1) { //登录取消
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateCancel, nil, error);
            } else  { //登录失败
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, error);
            }
            return ;
        }
        
    }];
    
    YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateBegin, nil, nil);
    
    
}

#pragma mark - QQ授权

+ (BOOL)installQQ {
    return [OpenShare isQQInstalled];
}

+ (void) ssoQQPlatformAuth {
    
    __weak YVShareSDKHelper *shareHelper = [YVShareSDKHelper shareHelper];
    if (![YVShareSDKHelper installQQ]) {
        YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"未安手机QQ,无法登陆" code:500 userInfo:nil]);
        return;
    }
    
    [OpenShare QQAuth:@"get_user_info" Success:^(NSDictionary *message) {
        //        NSLog(@"QQ登录成功\n%@",message);
        
        NSString *url = @"http://openapi.tencentyun.com/v3/user/get_info";
        NSMutableDictionary *params = @{@"appid": shareHelper.SSQQ.appId,
                                        @"openkey": message[@"access_token"],
                                        @"openid": message[@"openid"],
                                        @"pf": @"qzone",
                                        @"format": @"json"}.mutableCopy;
        NSMutableString *paramsString = (NSMutableString*)[NSString stringWithFormat:@"GET&%@&", [shareHelper encodeURLWithString:@"/v3/user/get_info"].mutableCopy];
        NSArray *keys = @[@"appid", @"format", @"openid", @"openkey", @"pf"];
        NSMutableString *keyValueString = @"".mutableCopy;
        for (NSString *key in keys) {
            [keyValueString appendFormat:@"%@=%@&", key, params[key]];
        }
        [keyValueString appendString:@"userip="];
        keyValueString       = [shareHelper encodeURLWithString:keyValueString].mutableCopy;
        [keyValueString appendString:@"10.0.0.1"];
        NSString *signStr = [NSString stringWithFormat:@"%@%@", paramsString, keyValueString];
        NSString *sss       = [shareHelper hmacSha1WithString:signStr forKey:[NSString stringWithFormat:@"%@&",shareHelper.SSQQ.appSecret]];
        NSString *sig       = [shareHelper encodeURLWithString:sss];
        params[@"sig"]       = sig;
        params[@"userip"] = @"10.0.0.1";
        
        NSMutableString *urlString = @"?".mutableCopy;
        for (NSString *key in params.allKeys) {
            [urlString appendFormat:@"%@=%@&", key, params[key]];
        }
        NSString *requestUrl = [NSString stringWithFormat:@"%@%@", url, urlString];
        requestUrl = [requestUrl substringToIndex:requestUrl.length - 1];
        
        [YVShareReqeust get:requestUrl completionHandler:^(NSDictionary *data, NSError *error) {
            NSMutableDictionary *dict = data.mutableCopy;
            [dict addEntriesFromDictionary:message];
            
#ifdef DEBUG
            NSLog(@"data:%@", dict);
            NSLog(@"error:%@", error);
#endif
            
            if (error || !dict) {
                
                if (shareHelper.loginCompletionBlock)
                    shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"QQ获取个人资料失败" code:1 userInfo:nil]);
            } else {
                
                shareHelper.authorizationUser                 = [[YVThirdUser alloc] init];
                shareHelper.authorizationUser.platformType   = YVThirdPlatformTypeQQ;
                NSString *icon                                     = dict[@"figureurl_2"];
                NSString *nickname                                   = dict[@"nickname"];
                NSString *gender                              = dict[@"gender"];
                NSString *access_token                         = dict[@"access_token"];
                NSString *openId                             = dict[@"openid"];
                
                shareHelper.authorizationUser.token             = access_token;
                shareHelper.authorizationUser.uid             = openId;
                shareHelper.authorizationUser.icon                 = icon;
                shareHelper.authorizationUser.nickname          = nickname;
                shareHelper.authorizationUser.gender          = [gender isEqualToString:@"男"] ? 1 : ([gender isEqualToString:@"女"] ? 2 : 0);
                if (shareHelper.loginCompletionBlock)
                    shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateSuccess, shareHelper.authorizationUser, NULL);
                
            }
            
        }];
        
    } Fail:^(NSDictionary *message, NSError *error) {
        //        NSLog(@"QQ登录失败\n%@\n%@",error,message);
        if (error) {
            NSInteger errorCode = error.code;
            if (errorCode == -1) { //登录取消
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateCancel, nil, error);
            } else  { //登录失败
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, error);
            }
            return ;
        }
    }];
    
    YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateBegin, nil, nil);
    
}

#pragma mark - 微信第三方登录

+ (BOOL)installWeChat {
    return [OpenShare isWeixinInstalled];
}

/**
 微信授权登录
 */
+ (void) ssoWechatPlatform {
    
    __weak YVShareSDKHelper *shareHelper = [YVShareSDKHelper shareHelper];
    if (![YVShareSDKHelper installWeChat]) {
        YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"未安装微信,无法登陆" code:500 userInfo:nil]);
        return;
    }
    
    [OpenShare WeixinAuth:@"snsapi_userinfo" Success:^(NSDictionary *message) {
        //        NSLog(@"微信登录成功:\n%@",message);
        NSString *appId = shareHelper.SSWechat.appId;
        NSString *secret = shareHelper.SSWechat.appSecret;
        NSString *url = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", appId, secret, message[@"code"]];
        
        [YVShareReqeust get:url completionHandler:^(NSDictionary *data, NSError *error) {
            NSString *accessToken = data[@"access_token"];
            NSString *openid = data[@"openid"];
            
            NSString *userInfoUrl = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@&lang=zh_CN", accessToken, openid];
            
            [YVShareReqeust get:userInfoUrl completionHandler:^(NSDictionary *userInfo, NSError *error) {
                NSMutableDictionary *dict = userInfo.mutableCopy;
                [dict addEntriesFromDictionary:message];
                if (error || !dict) {
                    if (shareHelper.loginCompletionBlock)
                        shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, [NSError errorWithDomain:@"微信获取个人资料失败" code:1 userInfo:nil]);
                } else {
                    
                    shareHelper.authorizationUser = [[YVThirdUser alloc] init];
                    shareHelper.authorizationUser.platformType = YVThirdPlatformTypeWeChat;
                    
                    NSString *openId = dict[@"openid"];
                    NSString *unionid = dict[@"unionid"];
                    NSString *headimgurl = dict[@"headimgurl"];
                    NSString *nickname = dict[@"nickname"];
                    NSString *sex = dict[@"sex"];
                    shareHelper.authorizationUser.icon = headimgurl;
                    shareHelper.authorizationUser.nickname = nickname;
                    shareHelper.authorizationUser.gender = sex.integerValue;
                    shareHelper.authorizationUser.uid = openId;
                    shareHelper.authorizationUser.token = unionid;
                    if (shareHelper.loginCompletionBlock)
                        shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateSuccess, shareHelper.authorizationUser, NULL);
                    
                }
            }];
            
        }];
        
        
    } Fail:^(NSDictionary *message, NSError *error) {
        //NSLog(@"微信登录失败:\n%@\n%@",message,error);
        if (error) {
            NSInteger errorCode = error.code;
            if (errorCode == -2) { //登录取消
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateCancel, nil, error);
            } else  { //登录失败
                shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateFailure, nil, error);
            }
        }
    }];
    
    YVShareSDKHelper.shareHelper.loginCompletionBlock(YVThirdPlatformResponseStateBegin, nil, nil);
    
}



/// 将字符串进行Url编码
- (NSString *) encodeURLWithString:(NSString *)string {
    NSCharacterSet *encodeUrlSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedString = [string stringByAddingPercentEncodingWithAllowedCharacters:encodeUrlSet];
    return encodedString;
}

/// 将字符串进行Hash
- (NSString *)hmacSha1WithString:(NSString *)string forKey:(NSString *)key  {
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [string cStringUsingEncoding:NSUTF8StringEncoding];
    char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA1_DIGEST_LENGTH];
    NSString *hash = [HMAC base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return hash;
}


#pragma mark - 第三方分享

/**
 开始第三方分享
 */
+(void)shareToThirdPlatform:(YVThirdPlatformType)platformType
               shareMessage:(YVShareMessage *)message
             onStateChanged:(YVThirdPlatformShareResponseState)statusChange {
    
    OSMessage *om = [[OSMessage alloc] init];
    om.title = message.title;
    om.link = message.link;
    om.desc = message.desc;
    om.image = message.image;
    
    if (platformType == YVThirdPlatformTypeQQ)  {
        [OpenShare shareToQQFriends:om Success:^(OSMessage *message) {
            NSLog(@"%@",message);
            !statusChange ?: statusChange(YVThirdPlatformResponseStateSuccess,nil);
        } Fail:^(OSMessage *message, NSError *error) {
            NSLog(@"%@",error.localizedDescription);
            !statusChange ?: statusChange(YVThirdPlatformResponseStateFailure,nil);
        }];
    } else if (platformType == YVThirdPlatformTypeWeChat)  {
    
        [OpenShare shareToWeixinSession:om Success:^(OSMessage *message) {
//            NSLog(@"%@",message);
            !statusChange ?: statusChange(YVThirdPlatformResponseStateSuccess,nil);
        } Fail:^(OSMessage *message, NSError *error) {
//            NSLog(@"%@",error.localizedDescription);
            !statusChange ?: statusChange(YVThirdPlatformResponseStateFailure,nil);
        }];
        
    }
 
    
}



@end

@implementation YVShareSDKPlatform

+ (instancetype)platformWithAppId:(NSString *)appId
                           appKey:(NSString *)aKey
                        appSecret:(NSString *)aSecret
                        redireUri:(NSString *)redireUri
{
    YVShareSDKPlatform *platform = [[YVShareSDKPlatform alloc] init];
    platform.appId = appId;
    platform.appKey = aKey;
    platform.appSecret = aSecret;
    platform.appRediretUri = redireUri;
    return platform;
}

@end

@implementation YVShareMessage



@end

@implementation YVThirdUser



@end





