//
//  EMCallViewController.h
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 22/11/2016.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DemoCallManager.h"

@interface EMCallViewController : UIViewController

#if DEMO_CALL == 1

@property (strong, nonatomic, readonly) EMCallSession *callSession;

@property (nonatomic) BOOL isDismissing;

- (instancetype)initWithCallSession:(EMCallSession *)aCallSession;

- (void)stateToConnected;

- (void)stateToAnswered;

- (void)clearData;

#endif

@end
