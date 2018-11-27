//
//  OpenShare+Alipay.m
//  openshare
//
//  Created by LiuLogan on 15/6/4.
//  Copyright (c) 2015年 OpenShare <http://openshare.gfzj.us/>. All rights reserved.
//

#import "OpenShare+Alipay.h"

@implementation OpenShare (Alipay)
static NSString* schema=@"Alipay";
/**
 *  支付宝支付参数都是从服务器获得的，所以不需要注册key。但是还是需要先connect向OpenShare注册，以便回调。
 */
+(void)connectAlipay{
    [self set:schema Keys:@{@"schema":schema}];
}

+(BOOL)isAlipayInstalled{
    return [self canOpen:@"alipay://"];
}
+(void)AliPay:(NSString*)link Success:(paySuccess)success Fail:(payFail)fail {
	[self setPaySuccessCallback:success];
	[self setPayFailCallback:fail];
	if ([self isAlipayInstalled]) {
		[OpenShare openURL:link];
	} else {
		fail(nil,[NSError errorWithDomain:@"未安装支付宝应用,无法支付" code:100 userInfo:nil]);
	}
}

+(BOOL) Alipay_handleOpenURL:(NSURL *)url {
    if ([url.absoluteString rangeOfString:@"//safepay/"].location != NSNotFound) {
        NSError *err;
        NSDictionary *ret=[NSJSONSerialization JSONObjectWithData:[[self urlDecode:url.query]dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&err];
        if (err||ret[@"memo"]==[NSNull null]||[ret[@"memo"][@"ResultStatus"] intValue]!=9000) {
            if ([self payFailCallback]) {
                [self payFailCallback](ret,err?:[NSError errorWithDomain:@"alipay_pay" code:ret[@"memo"]!=[NSNull null]?[ret[@"memo"][@"ResultStatus"] intValue]:-1 userInfo:ret]);
            }
        }else{
            if ([self paySuccessCallback]) {
                [self paySuccessCallback](ret);
            }
        }
        return YES;
    }else{
        return NO;
    }
}

@end
