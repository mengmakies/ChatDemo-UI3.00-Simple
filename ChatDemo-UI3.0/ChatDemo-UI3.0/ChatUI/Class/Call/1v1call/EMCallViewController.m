//
//  EMCallViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 22/11/2016.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import "EMCallViewController.h"

#if DEMO_CALL == 1

#import "DemoCallManager.h"
#import "EMVideoInfoViewController.h"

@interface EMCallViewController ()

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *remoteNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *remoteImgView;

@property (weak, nonatomic) IBOutlet UIView *actionView;
@property (weak, nonatomic) IBOutlet UIButton *speakerOutButton;
@property (weak, nonatomic) IBOutlet UIButton *silenceButton;
@property (weak, nonatomic) IBOutlet UIButton *minimizeButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;
@property (weak, nonatomic) IBOutlet UIButton *answerButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *showVideoInfoButton;

@property (strong, nonatomic) AVAudioPlayer *ringPlayer;
@property (nonatomic) int timeLength;
@property (strong, nonatomic) NSTimer *timeTimer;

@end

#endif

@implementation EMCallViewController

#if DEMO_CALL == 1

- (instancetype)initWithCallSession:(EMCallSession *)aCallSession
{
    NSString *xibName = @"EMCallViewController";
    self = [super initWithNibName:xibName bundle:nil];
    if (self) {
        _callSession = aCallSession;
        _isDismissing = NO;
    }
    
    return self;
}

#endif

- (void)viewDidLoad {
    if (self.isDismissing) {
        return;
    }
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
#if DEMO_CALL == 1
    
    [self _layoutSubviews];
    
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.isDismissing) {
        return;
    }
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.isDismissing) {
        return;
    }
    
    [super viewDidAppear:animated];
}

#if DEMO_CALL == 1

#pragma mark - private

- (void)_layoutSubviews
{
    [self.silenceButton setImage:[UIImage imageNamed:@"Button_Mute active"] forState:UIControlStateSelected];
    self.timeLabel.hidden = YES;
    self.remoteNameLabel.text = self.callSession.remoteName;
    
    BOOL isCaller = self.callSession.isCaller;
    switch (self.callSession.type) {
        case EMCallTypeVoice:
        {
            [self.speakerOutButton setImage:[UIImage imageNamed:@"Button_Speaker active"] forState:UIControlStateSelected];
            if (isCaller) {
                self.rejectButton.hidden = YES;
                self.answerButton.hidden = YES;
            } else {
                self.hangupButton.hidden = YES;
            }
        }
            break;
        case EMCallTypeVideo:
        {
            self.showVideoInfoButton.hidden = NO;
            self.speakerOutButton.hidden = YES;
            self.switchCameraButton.hidden = NO;
            
            if (isCaller) {
                self.rejectButton.hidden = YES;
                self.answerButton.hidden = YES;
            } else {
                self.hangupButton.hidden = YES;
            }
            
            [self _setupLocalVideoView];
//            [self.view bringSubviewToFront:self.topView];
//            [self.view bringSubviewToFront:self.actionView];
        }
            break;
            
        default:
            break;
    }
}

- (void)_setupRemoteVideoView
{
    if (self.callSession.type == EMCallTypeVideo && self.callSession.remoteVideoView == nil) {
        NSLog(@"\n########################_setupRemoteView");
        self.callSession.remoteVideoView = [[EMCallRemoteView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        self.callSession.remoteVideoView.hidden = YES;
        self.callSession.remoteVideoView.backgroundColor = [UIColor clearColor];
        self.callSession.remoteVideoView.scaleMode = EMCallViewScaleModeAspectFill;
        [self.view addSubview:self.callSession.remoteVideoView];
        [self.view sendSubviewToBack:self.callSession.remoteVideoView];
        
        __weak EMCallViewController *weakSelf = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            weakSelf.callSession.remoteVideoView.hidden = NO;
        });
    }
}

- (void)_setupLocalVideoView
{
    //2.自己窗口
    CGFloat width = 80;
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat height = size.height / size.width * width;
    self.callSession.localVideoView = [[EMCallLocalView alloc] initWithFrame:CGRectMake(size.width - width - 20, 20, width, height)];
    [self.view addSubview:self.callSession.localVideoView];
    [self.view bringSubviewToFront:self.callSession.localVideoView];
}

#pragma mark - private ring

- (void)_beginRing
{
    [self.ringPlayer stop];
    
    NSString *musicPath = [[NSBundle mainBundle] pathForResource:@"callRing" ofType:@"mp3"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath:musicPath];
    
    self.ringPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.ringPlayer setVolume:1];
    self.ringPlayer.numberOfLoops = -1; //设置音乐播放次数  -1为一直循环
    if([self.ringPlayer prepareToPlay])
    {
        [self.ringPlayer play]; //播放
    }
}

- (void)_stopRing
{
    [self.ringPlayer stop];
}

#pragma mark - private timer

- (void)timeTimerAction:(id)sender
{
    self.timeLength += 1;
    int hour = self.timeLength / 3600;
    int m = (self.timeLength - hour * 3600) / 60;
    int s = self.timeLength - hour * 3600 - m * 60;
    
    if (hour > 0) {
        self.timeLabel.text = [NSString stringWithFormat:@"%i:%i:%i", hour, m, s];
    }
    else if(m > 0){
        self.timeLabel.text = [NSString stringWithFormat:@"%i:%i", m, s];
    }
    else{
        self.timeLabel.text = [NSString stringWithFormat:@"00:%i", s];
    }
}

- (void)_startTimeTimer
{
    self.timeLength = 0;
    self.timeTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeTimerAction:) userInfo:nil repeats:YES];
}

- (void)_stopTimeTimer
{
    if (self.timeTimer) {
        [self.timeTimer invalidate];
        self.timeTimer = nil;
    }
}

#pragma mark - action

//- (IBAction)minimizeAction:(id)sender
//{
//    
//}

- (IBAction)speakerOutAction:(id)sender
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (self.speakerOutButton.selected) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    }else {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
    [audioSession setActive:YES error:nil];
    self.speakerOutButton.selected = !self.speakerOutButton.selected;
}

- (IBAction)silenceAction:(id)sender
{
    self.silenceButton.selected = !self.silenceButton.selected;
    if (self.silenceButton.selected) {
        [self.callSession pauseVoice];
    } else {
        [self.callSession resumeVoice];
    }
}

- (IBAction)switchCameraAction:(id)sender
{
    [self.callSession switchCameraPosition:self.switchCameraButton.selected];
    self.switchCameraButton.selected = !self.switchCameraButton.selected;
}

- (IBAction)showVideoInfoAction:(id)sender
{
    EMVideoInfoViewController *videoInfoController = [[EMVideoInfoViewController alloc] initWithNibName:@"EMVideoInfoViewController" bundle:nil];
    videoInfoController.callSession = self.callSession;
    videoInfoController.currentTime = self.timeLabel.text;
    [videoInfoController startTimer:self.timeLength];
    [self presentViewController:videoInfoController animated:YES completion:nil];
}

- (IBAction)answerAction:(id)sender
{
    [self _stopRing];
    [[DemoCallManager sharedManager] answerCall:self.callSession.callId];
}

- (IBAction)rejectAction:(id)sender
{
    [self _stopTimeTimer];
    [self _stopRing];
    
    [[DemoCallManager sharedManager] hangupCallWithReason:EMCallEndReasonDecline];
}

- (IBAction)hangupAction:(id)sender
{
    [self _stopTimeTimer];
    [self _stopRing];
    
    [[DemoCallManager sharedManager] hangupCallWithReason:EMCallEndReasonHangup];
}

#pragma mark - public

- (void)stateToConnecting
{
    if (self.callSession.isCaller) {
        self.statusLabel.text = NSLocalizedString(@"call.connecting", @"Connecting...");
    } else {
        self.statusLabel.text = NSLocalizedString(@"call.connecting", "Incoimg call");
    }
}

- (void)stateToConnected
{
    self.statusLabel.text = NSLocalizedString(@"call.finished", "Establish call finished");
}

- (void)stateToAnswered
{
    [self _startTimeTimer];
    
    if (self.callSession.type == EMCallTypeVideo) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        [audioSession setActive:YES error:nil];
    }
    
    NSString *connectStr = @"None";
    if (_callSession.connectType == EMCallConnectTypeRelay) {
        connectStr = @"Relay";
    } else if (_callSession.connectType == EMCallConnectTypeDirect) {
        connectStr = @"Direct";
    }
    
    self.statusLabel.text = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"call.speak", @"Can speak..."), connectStr];
    self.timeLabel.hidden = NO;
    self.hangupButton.hidden = NO;
    self.statusLabel.hidden = YES;
    self.rejectButton.hidden = YES;
    self.answerButton.hidden = YES;
    
    [self _setupRemoteVideoView];
}

- (void)clearData
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    [audioSession setActive:YES error:nil];
    
    self.callSession.remoteVideoView.hidden = YES;
    self.callSession.remoteVideoView = nil;
    _callSession = nil;
    
    [self _stopTimeTimer];
    [self _stopRing];
}

#endif

@end
