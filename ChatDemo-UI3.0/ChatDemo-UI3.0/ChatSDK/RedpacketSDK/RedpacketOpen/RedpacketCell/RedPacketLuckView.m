//
//  RedPacketLuckView.m
//  RedpacketDemo
//
//  Created by 都基鹏 on 2016/11/29.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RedPacketLuckView.h"


#define RedpacketViewHeight     140.0f
#define RedpacketViewWidth      116.0f

#define REDPACKETBUNDLE(name) [NSString stringWithFormat:@"RedpacketCellResource.bundle/%@", name]

@interface RedPacketLuckView()
@property (nonatomic,strong)UIButton * receiveButton;
@end

@implementation RedPacketLuckView

const CGFloat RedPacketLuckViewGreetingFontSize = 14;

+ (CGFloat)heightForRedpacketMessageCell
{
    return RedpacketViewHeight;
}

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, RedpacketViewWidth, RedpacketViewHeight)];
    if (self) {
        self.bubbleBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.bubbleBackgroundView];
        
        /** 设置红包祝福语 */
        self.greetingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.greetingLabel.font = [UIFont systemFontOfSize:14];
        self.greetingLabel.minimumScaleFactor = .6;
        self.greetingLabel.textColor = [UIColor colorWithRed:211/255.0f green:217/255.0f blue:122/255.0f alpha:1];
        self.greetingLabel.numberOfLines = 2;
        [self.greetingLabel setLineBreakMode:NSLineBreakByCharWrapping];
        [self.greetingLabel setTextAlignment:NSTextAlignmentCenter];
        [self.bubbleBackgroundView addSubview:self.greetingLabel];
        
        /** 抢红包按钮 */
        self.receiveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.receiveButton];
        [self.receiveButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        UIColor * receiveButtonColor = [UIColor colorWithRed:167/255.0f green:62/255.0f blue:54/255.0f alpha:1];
        [self.receiveButton setTitleColor:receiveButtonColor forState:UIControlStateNormal];
        [self.receiveButton setTitle:@"领取红包" forState:UIControlStateNormal];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.bubbleBackgroundView.frame = self.bounds;
    self.greetingLabel.frame = CGRectMake(25, 70, self.frame.size.width - 50, 36);
    self.receiveButton.frame = CGRectMake(0, self.frame.size.height - 34, self.frame.size.width, 34);
}

- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)model
{
    NSString * imageName =  model.isRedacketSender ? @"redpacket_em_random_chat_bg" : @"redpacket_em_random_chatfrom_bg";
    self.bubbleBackgroundView.image = [UIImage imageNamed:REDPACKETBUNDLE(imageName)];
    self.greetingLabel.text = model.redpacket.redpacketGreeting;
}

@end
