//
//  RedPacketLuckView.h
//  RedpacketDemo
//
//  Created by 都基鹏 on 2016/11/29.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedpacketMessageModel.h"

@interface RedPacketLuckView : UIView

@property(strong, nonatomic) UILabel *greetingLabel;
@property(strong, nonatomic) UIImageView *bubbleBackgroundView;


+ (CGFloat)heightForRedpacketMessageCell;
- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)model;

@end
