//
//  DemoCallManager.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 22/11/2016.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import "DemoCallManager.h"

#if DEMO_CALL == 1

#import "EaseSDKHelper.h"
//#import "EMVideoRecorderPlugin.h"

#import "EMCallViewController.h"

static DemoCallManager *callManager = nil;

@interface DemoCallManager()<EMChatManagerDelegate, EMCallManagerDelegate, EMCallBuilderDelegate>

@property (strong, nonatomic) NSObject *callLock;

@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) EMCallSession *currentSession;

@property (strong, nonatomic) EMCallViewController *currentController;

@end

#endif

@implementation DemoCallManager

#if DEMO_CALL == 1

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _initManager];
    }
    
    return self;
}

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        callManager = [[DemoCallManager alloc] init];
    });
    
    return callManager;
}

- (void)dealloc
{
    [[EMClient sharedClient].chatManager removeDelegate:self];
    [[EMClient sharedClient].callManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KNOTIFICATION_CALL object:nil];
}

#pragma mark - private

- (void)_initManager
{
    _callLock = [[NSObject alloc] init];
    _currentSession = nil;
    _currentController = nil;
    
    [[EMClient sharedClient].chatManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].callManager addDelegate:self delegateQueue:nil];
    [[EMClient sharedClient].callManager setBuilderDelegate:self];
    
//    [EMVideoRecorderPlugin initGlobalConfig];
    
    NSString *file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"calloptions.data"];
    EMCallOptions *options = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        options = [NSKeyedUnarchiver unarchiveObjectWithFile:file];
    } else {
        options = [[EMClient sharedClient].callManager getCallOptions];
        options.isSendPushIfOffline = NO;
        options.videoResolution = EMCallVideoResolution640_480;
        options.isFixedVideoResolution = YES;
    }
    [[EMClient sharedClient].callManager setCallOptions:options];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makeCall:) name:KNOTIFICATION_CALL object:nil];
}

- (void)_clearCurrentCallViewAndData
{
    @synchronized (_callLock) {
        self.currentSession = nil;
        
        self.currentController.isDismissing = YES;
        [self.currentController clearData];
        [self.currentController dismissViewControllerAnimated:NO completion:nil];
        self.currentController = nil;
    }
}

#pragma mark - private timer

- (void)_timeoutBeforeCallAnswered
{
    [self hangupCallWithReason:EMCallEndReasonNoResponse];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"call.autoHangup", @"No response and Hang up") delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)_startCallTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:50 target:self selector:@selector(_timeoutBeforeCallAnswered) userInfo:nil repeats:NO];
}

- (void)_stopCallTimer
{
    if (self.timer == nil) {
        return;
    }
    
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - EMChatManagerDelegate

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    for (EMMessage *message in aCmdMessages) {
        EMCmdMessageBody *cmdBody = (EMCmdMessageBody *)message.body;
        NSString *action = cmdBody.action;
        if ([action isEqualToString:@"inviteToJoinConference"]) {
            //            NSString *callId = [message.ext objectForKey:@"callId"];
        } else if ([action isEqualToString:@"__Call_ReqP2P_ConferencePattern"]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"已转为会议模式" delegate:self cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

#pragma mark - EMCallManagerDelegate

- (void)callDidReceive:(EMCallSession *)aSession
{
    if (!aSession || [aSession.callId length] == 0) {
        return ;
    }
    
    if ([EaseSDKHelper shareHelper].isShowingimagePicker) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"hideImagePicker" object:nil];
    }
    
    if(self.currentSession && self.currentSession.status != EMCallSessionStatusDisconnected){
        [[EMClient sharedClient].callManager endCall:aSession.callId reason:EMCallEndReasonBusy];
        return;
    }
    
    @synchronized (_callLock) {
        [self _startCallTimer];
        
        // 接收到语音通话请求时，保存对方传过来的昵称头像
        [UserCacheManager saveWithJson:aSession.ext];
        
        self.currentSession = aSession;
        self.currentController = [[EMCallViewController alloc] initWithCallSession:self.currentSession];
        self.currentController.modalPresentationStyle = UIModalPresentationOverFullScreen;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentController) {
                [self.mainController presentViewController:self.currentController animated:NO completion:nil];
            }
        });
    }
}

- (void)callDidConnect:(EMCallSession *)aSession
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [self.currentController stateToConnected];
    }
}

- (void)callDidAccept:(EMCallSession *)aSession
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        [self _stopCallTimer];
        [self.currentController stateToAnswered];
    }
}

- (void)callDidEnd:(EMCallSession *)aSession
            reason:(EMCallEndReason)aReason
             error:(EMError *)aError
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
        
        [self _stopCallTimer];
        
        @synchronized (_callLock) {
            self.currentSession = nil;
            [self _clearCurrentCallViewAndData];
        }
        
        if (aReason != EMCallEndReasonHangup) {
            NSString *reasonStr = @"end";
            switch (aReason) {
                case EMCallEndReasonNoResponse:
                {
                    reasonStr = NSLocalizedString(@"call.noResponse", @"NO response");
                }
                    break;
                case EMCallEndReasonDecline:
                {
                    reasonStr = NSLocalizedString(@"call.rejected", @"Reject the call");
                }
                    break;
                case EMCallEndReasonBusy:
                {
                    reasonStr = NSLocalizedString(@"call.in", @"In the call...");
                }
                    break;
                case EMCallEndReasonFailed:
                {
                    reasonStr = NSLocalizedString(@"call.connectFailed", @"Connect failed");
                }
                    break;
                case EMCallEndReasonUnsupported:
                {
                    reasonStr = NSLocalizedString(@"call.connectUnsupported", @"Unsupported");
                }
                    break;
                case EMCallEndReasonRemoteOffline:
                {
                    reasonStr = NSLocalizedString(@"call.offline", @"Remote offline");
                }
                    break;
                default:
                    break;
            }
            
            if (aError) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:aError.errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
            }
            else{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:reasonStr delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
    }
}

- (void)didReceiveCallNetworkChanged:(EMCallSession *)aSession status:(EMCallNetworkStatus)aStatus
{
    if ([aSession.callId isEqualToString:self.currentSession.callId]) {
//        [self.callController setNetwork:aStatus];
    }
}

#pragma mark - EMCallBuilderDelegate

- (void)callRemoteOffline:(NSString *)aRemoteName
{
    NSString *text = [[EMClient sharedClient].callManager getCallOptions].offlineMessageText;
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithText:text];
    NSString *fromStr = [EMClient sharedClient].currentUsername;
    EMMessage *message = [[EMMessage alloc] initWithConversationID:aRemoteName from:fromStr to:aRemoteName body:body ext:@{@"em_apns_ext":@{@"em_push_title":text}}];
    message.chatType = EMChatTypeChat;
    
    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:nil];
}

#pragma mark - NSNotification

- (void)makeCall:(NSNotification*)notify
{
    if (notify.object) {
        EMCallType type = (EMCallType)[[notify.object objectForKey:@"type"] integerValue];
        [self makeCallWithUsername:[notify.object valueForKey:@"chatter"] type:type];
    }
}

#pragma mark - public

- (void)saveCallOptions
{
    NSString *file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"calloptions.data"];
    EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
    [NSKeyedArchiver archiveRootObject:options toFile:file];
}

- (void)makeCallWithUsername:(NSString *)aUsername
                        type:(EMCallType)aType
{
    if ([aUsername length] == 0) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    void (^completionBlock)(EMCallSession *, EMError *) = ^(EMCallSession *aCallSession, EMError *aError){
        DemoCallManager *strongSelf = weakSelf;
        if (strongSelf) {
            if (aError || aCallSession == nil) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"call.initFailed", @"Establish call failure") message:aError.errorDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                [alertView show];
                return;
            }
            
            @synchronized (self.callLock) {
                strongSelf.currentSession = aCallSession;
                strongSelf.currentController = [[EMCallViewController alloc] initWithCallSession:strongSelf.currentSession];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (strongSelf.currentController) {
                        [strongSelf.mainController presentViewController:self.currentController animated:NO completion:nil];
                    }
                });
            }
            
            [self _startCallTimer];
        }
        else {
            [[EMClient sharedClient].callManager endCall:aCallSession.callId reason:EMCallEndReasonNoResponse];
        }
    };
    
    // 请求语音通话时，将昵称头像通过扩展属性传递过去
    NSString *ext = [[UserCacheManager getMyMsgExt] jsonStringEncoded];
    [[EMClient sharedClient].callManager startCall:aType remoteName:aUsername ext:ext completion:^(EMCallSession *aCallSession, EMError *aError) {
        completionBlock(aCallSession, aError);
    }];
}

- (void)answerCall:(NSString *)aCallId
{
    if (!self.currentSession || ![self.currentSession.callId isEqualToString:aCallId]) {
        return ;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient].callManager answerIncomingCall:weakSelf.currentSession.callId];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error.code == EMErrorNetworkUnavailable) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"network.disconnection", @"Network disconnection") delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
                    [alertView show];
                }
                else{
                    [weakSelf hangupCallWithReason:EMCallEndReasonFailed];
                }
            });
        }
    });
}

- (void)hangupCallWithReason:(EMCallEndReason)aReason
{
    [self _stopCallTimer];
    
    if (self.currentSession) {
        [[EMClient sharedClient].callManager endCall:self.currentSession.callId reason:aReason];
    }
    [self _clearCurrentCallViewAndData];
}


#endif

@end
