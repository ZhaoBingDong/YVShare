//
//  YVShareSDKHelper+Payment.m
//  YVThirdPart
//
//  Created by dzb on 2018/8/19.
//

#import "OpenShare+Weixin.h"
#import "OpenShare+Alipay.h"
#import "YVShareSDKHelper+Payment.h"

@implementation YVShareSDKHelper (Payment)

/**
 开始微信支付
 
 @param dict 支付参数
 @param success 支付成功
 @param fail 支付失败
 */
+ (void) WeixinPay:(NSDictionary *)dict
           Success:(YVWechatPaySuccess)success
              Fail:(YVWechatPayFailure)fail {
    
    if (![dict isKindOfClass:[NSDictionary class]]) {
        NSError *err;
        NSString *jsonStr =(NSString *)dict;
        dict = [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&err];
    }
    
    NSString *appId = YVShareSDKHelper.shareHelper.SSWechat.appId;
    NSString *noncestr = [dict objectForKey:@"noncestr"];
    NSString *partnerId = [dict objectForKey:@"partnerid"];
    NSString *prepayid = [dict objectForKey:@"prepayid"];
    NSString *timestamp = [dict objectForKey:@"timestamp"];
    NSString *sign = [dict objectForKey:@"sign"];
    NSString *weixinlink = [NSString stringWithFormat:@"weixin://app/%@/pay/?nonceStr=%@&package=Sign%%3DWXPay&partnerId=%@&prepayId=%@&timeStamp=%@&sign=%@&signType=SHA1",appId,noncestr,partnerId,prepayid,timestamp,sign];
    [OpenShare WeixinPay:weixinlink Success:^(NSDictionary *message) {
        if (success) {
            success(message);
        }
    } Fail:^(NSDictionary *message, NSError *error) {
        NSString *errMsg;
        if (error.code == -2) { /// 用户取消    无需处理。发生场景：用户不支付了，点击取消，返回APP。
            errMsg = @"用户中途取消付款";
        } else if (error.code == -1) { //错误 可能的原因：签名错误、未注册APPID、项目设置APPID不正确、注册的APPID与设置的不匹配、其他异常等。
            errMsg = @"微信支付失败";
        } else if (error.code == 0) { //成功    展示成功页面
            errMsg = @"支付成功";
        } else if (error.code == 100) {
            errMsg = error.domain;
        } else {
            errMsg = @"微信支付失败";
        }
        NSError *newErr = [NSError errorWithDomain:errMsg code:error.code userInfo:NULL];
        if (fail) {
            fail(message,newErr);
        }
    }];
    
}


/**
 *  支付接口
 *
 *  @param orderStr       订单信息
 *  @param schemeStr      调用支付的app注册在info.plist中的scheme
 *  @param completionBlock 支付结果回调Block，用于wap支付结果回调（非跳转钱包支付）
 */
+(void) AliPay:(NSString*)orderStr
    fromScheme:(NSString *)schemeStr
      callback:(YVAlipayCompletionBlock)completionBlock {
    
    NSString *jsonString;
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"fromAppUrlScheme"] = schemeStr;
    dictionary[@"requestType"] = @"SafePay";
    dictionary[@"dataString"] = orderStr;
#warning 替换成自己公司支付宝商户 appkey
	NSString *appKey = @"";
    dictionary[@"bizcontext"] = @{@"appkey" : appKey};
    
    NSData *data   = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:NULL];
    jsonString     = [self URLEncodedString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    NSString *link = [NSString stringWithFormat:@"alipay://alipayclient/?%@",jsonString];
    
    [OpenShare AliPay:link Success:^(NSDictionary *message) {
        
        NSDictionary *result   = [message objectForKey:@"memo"];
        NSString *resultStatus = [result objectForKey:@"ResultStatus"];
        BOOL succes = [resultStatus isEqualToString:@"9000"];
        NSString *errorString;
        if (succes) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"yiwei_noti_alipay_result" object:@{@"resultStatus" : resultStatus}];
        } else {
            errorString = [YVShareSDKHelper responseAliPayResultWithCode:resultStatus];
        }
        !completionBlock ?: completionBlock(succes,errorString);
        
    } Fail:^(NSDictionary *message, NSError *error) {
        BOOL paySuccess = NO;
        NSString *errorString;
        if (error.code == 100) {
            errorString = error.domain;
        } else {
            NSDictionary *result   = [message objectForKey:@"memo"];
            NSString *resultStatus = [result objectForKey:@"ResultStatus"];
            errorString = [YVShareSDKHelper responseAliPayResultWithCode:resultStatus];
        }
        !completionBlock ?: completionBlock(paySuccess,errorString);
    }];
    
    
}

///MARK:- 支付宝返回结果解析
+ (NSString *) responseAliPayResultWithCode:(NSString *)code {
    
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc]initWithCapacity:0];
    
    [tmpDict setObject:@"操作成功" forKey:@"9000"];
    [tmpDict setObject:@"正在处理中" forKey:@"8000"];
    [tmpDict setObject:@"系统异常" forKey:@"4000"];
    [tmpDict setObject:@"数据格式不正确" forKey:@"4001"];
    [tmpDict setObject:@"该用户绑定的支付宝账户被冻结或不允许支付" forKey:@"4003"];
    [tmpDict setObject:@"该用户已解除绑定" forKey:@"4004"];
    [tmpDict setObject:@"绑定失败或者没有绑定" forKey:@"4005"];
    [tmpDict setObject:@"订单支付失败" forKey:@"4006"];
    [tmpDict setObject:@"重新绑定账户" forKey:@"4010"];
    [tmpDict setObject:@"支付服务正在进行升级操作" forKey:@"6000"];
    [tmpDict setObject:@"用户中途取消支付" forKey:@"6001"];
    [tmpDict setObject:@"网络链接出错" forKey:@"6002"];
    
    NSString *resultMessage = [tmpDict objectForKey:code];
    if (!resultMessage) {
        resultMessage = @"支付未知错误";
    }
    
    UIViewController *rootVC = [YVShareSDKHelper currentViewController];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"支付结果" message:resultMessage preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:NULL]];
    [rootVC presentViewController:alertVC animated:YES completion:NULL];
    
    return resultMessage;
}


/**
 *  URLEncode
 */
+ (NSString *)URLEncodedString:(NSString *)string
{
    NSCharacterSet *encodeUrlSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedString         = [string stringByAddingPercentEncodingWithAllowedCharacters:encodeUrlSet];
    return encodedString;
}


+ (UIViewController*)topMostWindowController
{
    UIViewController *topController = [[UIApplication sharedApplication].delegate.window rootViewController];
    //  Getting topMost ViewController
    while ([topController presentedViewController])    topController = [topController presentedViewController];
    //  Returning topMost ViewController
    return topController;
}

+ (UIViewController*)currentViewController;
{
    UIViewController *currentViewController = [self topMostWindowController];
    
    if ([currentViewController isKindOfClass:[UITabBarController class]]) {
        currentViewController = [(UITabBarController *)currentViewController selectedViewController];
    }
    
    while ([currentViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)currentViewController topViewController])
        currentViewController = [(UINavigationController*)currentViewController topViewController];
    
    return currentViewController;
}


@end
