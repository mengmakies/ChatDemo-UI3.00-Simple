//
//  DemoCallManager.h
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 22/11/2016.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EMCallOptions+NSCoding.h"

@class MainViewController;
@interface DemoCallManager : NSObject

#if DEMO_CALL == 1

@property (strong, nonatomic) MainViewController *mainController;

+ (instancetype)sharedManager;

- (void)saveCallOptions;

- (void)makeCallWithUsername:(NSString *)aUsername
                        type:(EMCallType)aType;

- (void)answerCall:(NSString *)aCallId;

- (void)hangupCallWithReason:(EMCallEndReason)aReason;

#endif

@end
