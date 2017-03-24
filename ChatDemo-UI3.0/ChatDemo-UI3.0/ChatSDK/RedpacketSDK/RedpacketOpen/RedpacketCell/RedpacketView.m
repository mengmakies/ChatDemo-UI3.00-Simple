//
//  RedpacketView.m
//  RedpacketDemo
//
//  Created by Mr.Yang on 2016/11/21.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RedpacketView.h"

#define RedpacketMessageFontSize     14
#define RedpacketSubMessageFontSize  12
#define RedpacketViewHeight          94
#define RedpacketViewWidth           218
#define RedpacketLeftMargin          10
#define RedpacketTopMargin           19
#define RedpacketIconHeight          34
#define RedpacketIconWidth           26
#define RedpacketInsetX              7
#define RedpacketLabelHeight         15
#define RedapcketLabelHBottom        25

#define RedpacketImageInset         UIEdgeInsetsMake(70, 9, 25, 20)
#define RedpacketViewRect           CGRectMake(0, 0, RedpacketViewWidth, RedpacketViewHeight)

#define RedpacketDirectText         NSLocalizedString(@"专属红包", @"专属红包")
#define RedpacketTransfer           NSLocalizedString(@"红包转账", @"红包转账")
#define RedpacketSubMessageText     NSLocalizedString(@"查看红包", @"查看红包")
#define RedpacketTransferSeText     NSLocalizedString(@"对方已收到转账", @"对方已收到转账")
#define RedpacketTransferReceText   NSLocalizedString(@"已收到对方转账", @"已收到对方转账")

#define REDPACKETBUNDLE(name) [NSString stringWithFormat:@"RedpacketCellResource.bundle/%@", name]


@implementation RedpacketView

+ (CGFloat)redpacketViewHeight
{
    return RedpacketViewHeight;
}

- (instancetype)init
{
    self =  [super initWithFrame:RedpacketViewRect];
    if (self) {
        
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    self.bubbleBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:self.bubbleBackgroundView];
    
    /** 设置红包图标 */
    self.iconView = [[UIImageView alloc] initWithImage:[[UIImage alloc] init]];
    [self.bubbleBackgroundView addSubview:self.iconView];
    
    /** 设置红包祝福语 */
    self.greetingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.greetingLabel.font = [UIFont systemFontOfSize:RedpacketMessageFontSize];
    self.greetingLabel.minimumScaleFactor = .6;
    self.greetingLabel.textColor = [UIColor whiteColor];
    self.greetingLabel.numberOfLines = 1;
    [self.greetingLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.greetingLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.greetingLabel];
    
    /** 设置红包描述 */
    self.subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.subLabel.font = [UIFont systemFontOfSize:RedpacketSubMessageFontSize];
    self.subLabel.numberOfLines = 1;
    self.subLabel.textColor = [UIColor whiteColor];
    [self.subLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.subLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.subLabel];
    
    /** 红包出处 */
    self.orgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.orgLabel.font = [UIFont systemFontOfSize:RedpacketSubMessageFontSize];
    self.orgLabel.numberOfLines = 1;
    self.orgLabel.textColor = [UIColor lightGrayColor];
    [self.orgLabel setLineBreakMode:NSLineBreakByCharWrapping];
    [self.orgLabel setTextAlignment:NSTextAlignmentLeft];
    [self.bubbleBackgroundView addSubview:self.orgLabel];
    
    /** 红包类型 */
    self.typeLable = [[UILabel alloc]initWithFrame:CGRectZero];
    self.typeLable.font = [UIFont systemFontOfSize:RedpacketSubMessageFontSize];
    self.typeLable.textColor = [UIColor redColor];
    self.typeLable.textAlignment = NSTextAlignmentRight;
    [self.bubbleBackgroundView addSubview:self.typeLable];
}

- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)redpacketMessage
                        andRedpacketDic:(NSDictionary *)redpacketDic
{
    NSString *title;
    NSString *subTitle;
    NSString *orgTitle;
    UIImage  *icon;
    NSString *imageName;
    
    BOOL isSender = redpacketMessage.isRedacketSender;
    
    if (redpacketMessage.messageType == RedpacketMessageTypeTransfer) {
        imageName = isSender ? @"transfer_sender_bg" : @"transfer_receiver_bg";
        icon = [UIImage imageNamed:REDPACKETBUNDLE(@"redPacket_transferIcon")];
        title = redpacketMessage.isRedacketSender ? RedpacketTransferSeText : RedpacketTransferReceText;
        subTitle = [NSString stringWithFormat:@"%@元", redpacketDic[@"money_transfer_amount"]];
        orgTitle = RedpacketTransfer;
    }else {
        imageName = isSender ? @"redpacket_sender_bg" : @"redpacket_receiver_bg";
        icon = [UIImage imageNamed:REDPACKETBUNDLE(@"redPacket_redPacktIcon")];
        title = redpacketMessage.redpacket.redpacketGreeting;
        subTitle = RedpacketSubMessageText;
        orgTitle = redpacketMessage.redpacket.redpacketOrgName;
        if (redpacketMessage.redpacketType == RedpacketTypeMember) {
            self.typeLable.hidden = NO;
            self.typeLable.text = RedpacketDirectText;
        }else {
            self.typeLable.hidden = YES;
        }
    }
    self.iconView.image = icon;
    self.greetingLabel.text = title;
    self.subLabel.text = subTitle;
    self.orgLabel.text = orgTitle;
    UIImage *image = [UIImage imageNamed:REDPACKETBUNDLE(imageName)];
    image = [image resizableImageWithCapInsets:RedpacketImageInset];
    self.bubbleBackgroundView.image = image;
    [self layoutSubviewsWithModel:redpacketMessage];
}

- (void)layoutSubviewsWithModel:(RedpacketMessageModel *)model
{
    CGRect frame;
    CGSize iconSize;
    
    if (model.messageType == RedpacketMessageTypeTransfer) {
        iconSize = CGSizeMake(RedpacketIconHeight, RedpacketIconHeight);
        
    }else {
        iconSize = CGSizeMake(RedpacketIconWidth, RedpacketIconHeight);
    }
    
    self.iconView.frame = CGRectMake(RedpacketLeftMargin,
                                     RedpacketTopMargin,
                                     iconSize.width,
                                     iconSize.height);
    
    CGFloat leftX = CGRectGetMaxX(self.iconView.frame) + RedpacketLeftMargin;
    self.greetingLabel.frame = CGRectMake(leftX,
                                          RedpacketTopMargin,
                                          RedpacketViewWidth - leftX,
                                          RedpacketLabelHeight);
    
    frame = self.greetingLabel.frame;
    frame.origin.y = CGRectGetMaxY(self.iconView.frame) - RedpacketLabelHeight;
    self.subLabel.frame = frame;
    
    self.orgLabel.frame = CGRectMake(RedpacketLeftMargin,
                                     RedpacketViewHeight - RedapcketLabelHBottom,
                                     RedpacketViewWidth - RedpacketLeftMargin * 2,
                                     RedapcketLabelHBottom);
    
    
    frame.origin.x = RedpacketViewWidth - RedpacketLeftMargin;
    self.typeLable.frame = CGRectMake(RedpacketLeftMargin,
                                      RedpacketViewHeight - RedapcketLabelHBottom,
                                      RedpacketViewWidth - RedpacketLeftMargin * 2,
                                      RedapcketLabelHBottom);
    
    if (!model.isRedacketSender) {
        for (UIView *view in self.bubbleBackgroundView.subviews) {
            
            CGRect frame = view.frame;
            frame.origin.x += RedpacketInsetX;
            
            view.frame = frame;
        }
    }
}

@end
