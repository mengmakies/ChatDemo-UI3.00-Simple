/************************************************************
 *  * Hyphenate CONFIDENTIAL
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Inc.
 */

#import "AppDelegate+EaseMobDebug.h"

#import <Hyphenate/EMOptions+PrivateDeploy.h>

#warning Internal testing, developers do not need to use

@implementation AppDelegate (EaseMobDebug)

-(BOOL)isSpecifyServer{
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    NSNumber *specifyServer = [ud objectForKey:@"identifier_enable"];
    if ([specifyServer boolValue]) {
        NSString *apnsCertName = nil;
#if DEBUG
        apnsCertName = @"chatdemoui_dev";
#else
        apnsCertName = @"chatdemoui";
#endif
        NSString *appkey = [ud stringForKey:@"identifier_appkey"];
        if (!appkey)
        {
            appkey = @"easemob-demo#chatdemoui";
            [ud setObject:appkey forKey:@"identifier_appkey"];
        }
        NSString *imServer = [ud stringForKey:@"identifier_imserver"];
        if (!imServer)
        {
            imServer = @"msync-im1.sandbox.easemob.com";
            [ud setObject:imServer forKey:@"identifier_imserver"];
        }
        NSString *imPort = [ud stringForKey:@"identifier_import"];
        if (!imPort)
        {
            imPort = @"6717";
            [ud setObject:imPort forKey:@"identifier_import"];
        }
        NSString *restServer = [ud stringForKey:@"identifier_restserver"];
        if (!restServer)
        {
            restServer = @"a1.sdb.easemob.com";
            [ud setObject:restServer forKey:@"identifier_restserver"];
        }
        
        BOOL isHttpsOnly = NO;
        NSNumber *httpsOnly = [ud objectForKey:@"identifier_httpsonly"];
        if (httpsOnly) {
            isHttpsOnly = [httpsOnly boolValue];
        }
        
        [ud synchronize];
        
        EMOptions *options = [EMOptions optionsWithAppkey:appkey];
        if (![ud boolForKey:@"enable_dns"])
        {
            options.enableDnsConfig = NO;
            options.chatPort = [[ud stringForKey:@"identifier_import"] intValue];
            options.chatServer = [ud stringForKey:@"identifier_imserver"];
            options.restServer = [ud stringForKey:@"identifier_restserver"];
        }
        //    EMOptions *options = [EMOptions optionsWithAppkey:@"easemob-demo#chatdemoui"];
        options.apnsCertName = @"chatdemoui_dev";
        options.enableConsoleLog = YES;
        options.usingHttpsOnly = isHttpsOnly;
        
        [[EMClient sharedClient] initializeSDKWithOptions:options];
        return YES;
    }
    
    return NO;
}
@end
