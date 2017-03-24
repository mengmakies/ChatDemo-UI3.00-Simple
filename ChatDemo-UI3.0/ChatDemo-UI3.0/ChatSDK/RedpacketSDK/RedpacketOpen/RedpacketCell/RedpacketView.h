//
//  RedpacketView.h
//  RedpacketDemo
//
//  Created by Mr.Yang on 2016/11/21.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedpacketMessageModel.h"

/** 默认红包视图 */
@interface RedpacketView : UIView

@property(strong, nonatomic) UILabel *greetingLabel;
@property(strong, nonatomic) UILabel *subLabel;
@property(strong, nonatomic) UILabel *orgLabel;
@property(strong, nonatomic) UILabel *typeLable;
@property(strong, nonatomic) UIImageView *iconView;
@property(strong, nonatomic) UIImageView *bubbleBackgroundView;

+ (CGFloat)redpacketViewHeight;

- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)redpacketMessage
                        andRedpacketDic:(NSDictionary *)redpacketDic;

@end
