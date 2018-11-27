//
//  YVShareSDKHelper.h
//  YVPin
//
//  Created by dzb on 2017/11/30.
//  Copyright © 2017年 大兵布莱恩特. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class YVThirdUser;
@class YVShareMessage;

/**
 第三方平台类型

 - YVThridPlatformTypeQQ:  	  QQ平台
 - YVThridPlatformTypeWeibo:  新浪微博平台
 - YVThridPlatformTypeWeChat: 微信
 */
typedef NS_ENUM(NSUInteger, YVThirdPlatformType) {
	YVThirdPlatformTypeQQ			= 1,
	YVThirdPlatformTypeWeibo		= 2,
	YVThirdPlatformTypeWeChat		= 3,
};


/**
 第三方平台授权状态码

 - YVThirdPlatformResponseStateBegin: 开始
 - YVThirdPlatformResponseStateSuccess: 成功
 - YVThirdPlatformResponseStateFailure: 失败
 - YVThirdPlatformResponseStateCancel: 取消
 */
typedef NS_ENUM(NSUInteger, YVThirdResponseState) {
	YVThirdPlatformResponseStateBegin		= 0,
	YVThirdPlatformResponseStateSuccess		= 1,
	YVThirdPlatformResponseStateFailure		= 2,
	YVThirdPlatformResponseStateCancel		= 3,
};

typedef void(^YVThirdPlatformLoginResponseState)(YVThirdResponseState state, YVThirdUser *user, NSError *error);

typedef void(^YVThirdPlatformShareResponseState)(YVThirdResponseState state,NSError *error);


@class YVShareSDKPlatform;

@interface YVShareSDKHelper : NSObject

@property (nonatomic,strong,class) YVShareSDKHelper *shareHelper;
@property (nonatomic,strong) YVShareSDKPlatform *SSSina;
@property (nonatomic,strong) YVShareSDKPlatform *SSQQ;
@property (nonatomic,strong) YVShareSDKPlatform *SSWechat;

///isInstallWeCaht
@property (class,nonatomic,assign,readonly) BOOL installWeChat;
///isInstallWeCaht
@property (class,nonatomic,assign,readonly) BOOL installWeibo;
///isInstallWeCaht
@property (class,nonatomic,assign,readonly) BOOL installQQ;

/**
 初始化ShareSDK
 */
- (void) registerActivePlatforms;

/**
 获取用户信息

 @param platformType 第三方平台类型车
 @param statusChange 获取用户信息状态发生改变
 */
+ (void) getUserInfo:(YVThirdPlatformType)platformType
	  onStateChanged:(YVThirdPlatformLoginResponseState)statusChange;

/**
 开始第三方分享
 */
+(void)shareToThirdPlatform:(YVThirdPlatformType)platformType
               shareMessage:(YVShareMessage *)message
             onStateChanged:(YVThirdPlatformShareResponseState)statusChange;

/**
 处理程序通过URL启动第三方应用时传递的数据
 
 需要在 application:openURL:sourceApplication:annotation:或者application:handleOpenURL中调用
 @param url 启动第三方应用的URL
 */
- (BOOL) handleOpenURL:(NSURL *)url;


@end

/**
 第三方平台应用信息
 */
@interface YVShareSDKPlatform : NSObject

///appId
@property (nonatomic,copy) NSString *appId;

///appKey
@property (nonatomic,copy) NSString *appKey;

///appSecret
@property (nonatomic,copy) NSString *appSecret;

///appRediretUri
@property (nonatomic,copy) NSString *appRediretUri;

/**
 实例化YVShareSDKPlatform

 @param appId 平台的 AppId
 @param aKey  各个平台的 AppKey
 @param aSecret  第三方平台的appSecret
 @param redireUri 第三方平台的redireUri
 @return 返回实例
 */
+ (instancetype) platformWithAppId:(NSString *)appId
                            appKey:(NSString *)aKey
                         appSecret:(NSString *)aSecret
                         redireUri:(NSString *)redireUri;


@end

@interface YVShareMessage : NSObject

@property (nonatomic,copy) NSString *title;
@property (nonatomic,copy) NSString *desc;
@property (nonatomic,copy) NSString *link;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) UIImage *thumbnail;

@end

/**
 第三方平台用户信息
 */
@interface YVThirdUser : NSObject


/**
 *  平台类型
 */
@property (nonatomic) YVThirdPlatformType platformType;

/**
 *  用户令牌
 */
@property (nonatomic, copy) NSString *token;


/**
 *  用户标识
 */
@property (nonatomic, copy) NSString *uid;

/**
 *  昵称
 */
@property (nonatomic, copy) NSString *nickname;

/**
 *  头像
 */
@property (nonatomic, copy) NSString *icon;

/**
 *  性别 1 男 2 女 0 未知
 */
@property (nonatomic) NSInteger gender;


@end


