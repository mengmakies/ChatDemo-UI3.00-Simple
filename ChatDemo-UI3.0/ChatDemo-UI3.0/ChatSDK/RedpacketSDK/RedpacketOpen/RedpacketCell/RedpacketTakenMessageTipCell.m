//
//  RedpacketTakenMessageTipCell.m
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-7.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import "RedpacketTakenMessageTipCell.h"

#define REDPACKET_BUNDLE(name) @"RedpacketCellResource.bundle/" name
#define BACKGROUND_LEFT_RIGHT_PADDING 10
#define ICON_LEFT_RIGHT_PADDING 2
#define REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING 10

@interface RedpacketTakenMessageTipCell ()

@property(nonatomic, weak) UIView *baseContentView;

@property(nonatomic, strong) UIView *bgView;
@property(nonatomic, strong) UILabel *tipMessageLabel;
@property(nonatomic, strong) UIImageView *iconView;

@end

@implementation RedpacketTakenMessageTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.baseContentView = self.contentView;
        
        [self initialize];
    }
    
    return self;
}


- (void)initialize {
    
    self.baseContentView.backgroundColor = [UIColor clearColor];
    
    self.bgView = [[UIView alloc] initWithFrame:self.baseContentView.bounds];
    self.bgView.userInteractionEnabled = NO;
    self.bgView.backgroundColor = [self hexColor:0xe3e3e3];
    
    self.bgView.autoresizingMask = UIViewAutoresizingNone;
    self.bgView.layer.cornerRadius = 4.0f;
    [self.baseContentView addSubview:self.bgView];
    
    self.tipMessageLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.tipMessageLabel.font = [UIFont systemFontOfSize:12];
    self.tipMessageLabel.textColor = [UIColor grayColor];
    self.tipMessageLabel.userInteractionEnabled = NO;
    self.tipMessageLabel.numberOfLines = 1;
    [self.bgView addSubview:self.tipMessageLabel];
    
    self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 15)];
    self.iconView.image = [UIImage imageNamed:REDPACKET_BUNDLE(@"redpacket_smallIcon")];
    self.iconView.userInteractionEnabled = NO;
    [self.bgView addSubview:self.iconView];
}

- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)redpacketModel
{
    NSString *message;
    if (redpacketModel.isRedacketSender) {
        message = [NSString stringWithFormat:@"%@领取了你的红包", redpacketModel.redpacketReceiver.userNickname];
       
    }else {
        message = [NSString stringWithFormat:@"你领取了%@的红包", redpacketModel.redpacketSender.userNickname];
    }
    
    self.bgView.hidden = NO;
    self.tipMessageLabel.text = message;
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.tipMessageLabel sizeToFit];
    
    CGRect frame = self.tipMessageLabel.frame;
    CGRect iconFrame = self.iconView.frame;
    CGRect bgFrame = CGRectMake(0, 0,
                                frame.size.width + iconFrame.size.width + 2 * BACKGROUND_LEFT_RIGHT_PADDING,
                                22);
    
    frame.origin.y = (bgFrame.size.height - frame.size.height) * 0.5;
    iconFrame.origin.x = BACKGROUND_LEFT_RIGHT_PADDING - ICON_LEFT_RIGHT_PADDING;
    iconFrame.origin.y = frame.origin.y + (frame.size.height - iconFrame.size.height) * 0.5;
    self.iconView.frame = iconFrame;
    
    frame.origin.x = ICON_LEFT_RIGHT_PADDING + iconFrame.origin.x + iconFrame.size.width;
    self.tipMessageLabel.frame = frame;
    
    
    bgFrame.origin.y = REDPACKET_TAKEN_MESSAGE_TOP_BOTTOM_PADDING;
    bgFrame.origin.x = (self.baseContentView.bounds.size.width - bgFrame.size.width) * 0.5;
    
    self.bgView.frame = bgFrame;
}

+ (CGFloat)heightForRedpacketMessageTipCell
{
    return 40.0f;
}

- (UIColor *)hexColor:(uint)color
{
    float r = (color&0xFF0000) >> 16;
    float g = (color&0xFF00) >> 8;
    float b = (color&0xFF);
    
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f];
}


@end
