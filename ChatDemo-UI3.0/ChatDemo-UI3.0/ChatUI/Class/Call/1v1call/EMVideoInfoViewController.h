//
//  EMVideoInfoViewController.h
//  ChatDemo-UI3.0
//
//  Created by EaseMob on 16/10/10.
//  Copyright © 2016年 easemob. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DemoCallManager.h"

@interface EMVideoInfoViewController : UIViewController

@property (nonatomic, weak) EMCallSession *callSession;

@property (nonatomic, copy) NSString *currentTime;

@property (nonatomic, assign) int timeLength;


- (void)startTimer:(int)currentTimeLength;

@end
