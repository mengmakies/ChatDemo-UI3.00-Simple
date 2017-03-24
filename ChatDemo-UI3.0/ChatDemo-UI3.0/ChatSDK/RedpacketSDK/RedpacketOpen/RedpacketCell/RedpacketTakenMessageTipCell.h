//
//  RedpacketTakenMessageTipCell.h
//  LeanChat
//
//  Created by YANG HONGBO on 2016-5-7.
//  Copyright © 2016年 云帐户. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedpacketMessageModel.h"

@interface RedpacketTakenMessageTipCell : UITableViewCell

- (void)configWithRedpacketMessageModel:(RedpacketMessageModel *)model;

+ (CGFloat)heightForRedpacketMessageTipCell;

@end
