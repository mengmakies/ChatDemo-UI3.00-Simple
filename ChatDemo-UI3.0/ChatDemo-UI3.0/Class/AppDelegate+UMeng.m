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

#import "AppDelegate+UMeng.h"
#import "MobClick.h"

@implementation AppDelegate (UMeng)

-(void)setupUMeng{
    //友盟
    NSString *bundleID = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    if ([bundleID isEqualToString:@"com.easemob.enterprise.demo.ui"]) {
        [MobClick startWithAppkey:@"56f36884e0f55a7d4c001ff1"
                     reportPolicy:BATCH
                        channelId:nil];
#if DEBUG
        [MobClick setLogEnabled:YES];
#else
        [MobClick setLogEnabled:NO];
#endif
    }
}

@end
