//
//  YVShareSDKHelper+Payment.h
//  YVThirdPart
//
//  Created by dzb on 2018/8/19.
//

#import "YVShareSDKHelper.h"

NS_ASSUME_NONNULL_BEGIN

///微信支付成功回调
typedef void(^YVWechatPaySuccess)(NSDictionary *message);
///微信支付失败回调
typedef void(^YVWechatPayFailure)(NSDictionary *message, NSError *error);
///支付支付结果回调
typedef void(^YVAlipayCompletionBlock)(BOOL paySuccess,NSString * _Nullable errorString);

/**
 YVShare 支付功能
 */
@interface YVShareSDKHelper (Payment)

/**
 开始微信支付
 
 @param dict 支付参数
 @param success 支付成功
 @param fail 支付失败
 */
+ (void) WeixinPay:(NSDictionary *)dict
           Success:(YVWechatPaySuccess)success
              Fail:(YVWechatPayFailure)fail;


/**
 *  支付接口
 *
 *  @param orderStr       订单信息
 *  @param schemeStr      调用支付的app注册在info.plist中的scheme
 *  @param completionBlock 支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
 */
+(void) AliPay:(NSString *)orderStr
    fromScheme:(NSString *)schemeStr
      callback:(_Nullable YVAlipayCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
