/************************************************************
  *  * Hyphenate CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2016 Hyphenate Inc. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of Hyphenate Inc.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from Hyphenate Inc.
  */

#import "LoginViewController.h"
#import "EMError.h"
#import "ChatUIHelper.h"
#import "MBProgressHUD.h"
#import "RedPacketUserConfig.h"

@interface LoginViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *useIpSwitch;

- (IBAction)doRegister:(id)sender;
- (IBAction)doLogin:(id)sender;
- (IBAction)useIpAction:(id)sender;

@end

@implementation LoginViewController

@synthesize usernameTextField = _usernameTextField;
@synthesize passwordTextField = _passwordTextField;
@synthesize registerButton = _registerButton;
@synthesize loginButton = _loginButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupForDismissKeyboard];
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    NSString *username = [self lastLoginUsername];
    if (username && username.length > 0) {
        _usernameTextField.text = username;
    }
    
//    [_useIpSwitch setOn:[[EMClient sharedClient].options enableDnsConfig] animated:YES];
    
    self.title = NSLocalizedString(@"AppName", @"EaseMobDemo");
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//注册账号
//Registered account
- (IBAction)doRegister:(id)sender {
    if (![self isEmpty]) {
        //隐藏键盘
        [self.view endEditing:YES];
        //判断是否是中文，但不支持中英文混编
        if ([self.usernameTextField.text isChinese]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.nameNotSupportZh", @"Name does not support Chinese")
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                  otherButtonTitles:nil];
            
            [alert show];
            
            return;
        }
        [self showHudInView:self.view hint:NSLocalizedString(@"register.ongoing", @"Is to register...")];
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            EMError *error = [[EMClient sharedClient] registerWithUsername:weakself.usernameTextField.text password:weakself.passwordTextField.text];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself hideHud];
                if (!error) {
                    TTAlertNoTitle(NSLocalizedString(@"register.success", @"Registered successfully, please log in"));
                }else{
                    switch (error.code) {
                        case EMErrorServerNotReachable:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                            break;
                        case EMErrorUserAlreadyExist:
                            TTAlertNoTitle(NSLocalizedString(@"register.repeat", @"You registered user already exists!"));
                            break;
                        case EMErrorNetworkUnavailable:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                            break;
                        case EMErrorServerTimeout:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                            break;
                        case EMErrorServerServingForbidden:
                            TTAlertNoTitle(NSLocalizedString(@"servingIsBanned", @"Serving is banned"));
                            break;
                        default:
                            TTAlertNoTitle(NSLocalizedString(@"register.fail", @"Registration failed"));
                            break;
                    }
                }
            });
        });
    }
}

//点击登陆后的操作
- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
    [self showHudInView:self.view hint:NSLocalizedString(@"login.ongoing", @"Is Login...")];
    //异步登陆账号
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient] loginWithUsername:username password:password];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself hideHud];
            if (!error) {
                
                // -----测试：登录成功后，自动添加martin1234为好友-----------------
                EMError *error = [[EMClient sharedClient].contactManager addContact:@"martin1234" message:@"江南孤鹜让我加你为好友~"];
                if (!error) {
                    NSLog(@"添加成功");
                    // 测试发送消息
                    [self sendChatMsg:@"martin1234"
                                 text:@"可否到github上给简版demo一个star？ ☺ https://github.com/mengmakies/ChatDemo-UI3.00-Simple"];
                }
                // -----测试：登录成功后，自动添加martin1234为好友--------end---------
                
                NSString *userOpenId = username;// 用户环信ID
                NSString *nickName = [NSString stringWithFormat:@"小草%d", arc4random_uniform(100)];// 用户昵称
                NSString *avatarUrl = @"http://avatar.csdn.net/E/8/5/2_duruiqi_fx.jpg";// 用户头像（绝对路径）
                
                // 登录成功后，如果后端云没有缓存用户信息，则新增一个用户
                [UserWebManager createUser:userOpenId nickName:nickName avatarUrl:avatarUrl];
                
                // 通过消息的扩展属性传递昵称和头像时，需要调用这句代码缓存
//                [UserCacheManager saveInfo:userOpenId imgUrl:avatarUrl nickName:nickName];
                
                //设置是否自动登录
                [[EMClient sharedClient].options setIsAutoLogin:YES];
                
                //获取数据库中数据
                [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[EMClient sharedClient] migrateDatabaseToLatestSDK];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[ChatUIHelper shareHelper] asyncGroupFromServer];
                        [[ChatUIHelper shareHelper] asyncConversationFromDB];
                        [[ChatUIHelper shareHelper] asyncPushOptions];
                        [MBProgressHUD hideAllHUDsForView:weakself.view animated:YES];
                        //发送自动登陆状态通知
                        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@([[EMClient sharedClient] isLoggedIn])];
                        
                        //保存最近一次登录用户名
                        [weakself saveLastLoginUsername];
                    });
                });
            } else {
                switch (error.code)
                {
//                    case EMErrorNotFound:
//                        TTAlertNoTitle(error.errorDescription);
//                        break;
                    case EMErrorNetworkUnavailable:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                        break;
                    case EMErrorServerNotReachable:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                        break;
                    case EMErrorUserAuthenticationFailed:
                        TTAlertNoTitle(error.errorDescription);
                        break;
                    case EMErrorServerTimeout:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                        break;
                    case EMErrorServerServingForbidden:
                        TTAlertNoTitle(NSLocalizedString(@"servingIsBanned", @"Serving is banned"));
                        break;
                    default:
                        TTAlertNoTitle(NSLocalizedString(@"login.fail", @"Login failure"));
                        break;
                }
            }
        });
    });
}

// 测试发送消息
-(void)sendChatMsg:(NSString*)toUserId
              text:(NSString*)text{
    EMMessage *message = [EaseSDKHelper sendTextMessage:text
                                                     to:toUserId
                                            messageType:EMChatTypeChat
                                             messageExt:nil];

    [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:^(EMMessage *aMessage, EMError *aError) {
        if (!aError) {
            
        }
    }];
}

//弹出提示的代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView cancelButtonIndex] != buttonIndex) {
        //获取文本输入框
        UITextField *nameTextField = [alertView textFieldAtIndex:0];
        if(nameTextField.text.length > 0)
        {
            //设置推送设置
            [[EMClient sharedClient] setApnsNickname:nameTextField.text];
        }
    }
    //登陆
    [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
}

//登陆账号
- (IBAction)doLogin:(id)sender {
    if (![self isEmpty]) {
        [self.view endEditing:YES];
        //支持是否为中文
        if ([self.usernameTextField.text isChinese]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"login.nameNotSupportZh", @"Name does not support Chinese")
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                  otherButtonTitles:nil];
            
            [alert show];
            
            return;
        }
        /*
#if !TARGET_IPHONE_SIMULATOR
        //弹出提示
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"login.inputApnsNickname", @"Please enter nickname for apns") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        UITextField *nameTextField = [alert textFieldAtIndex:0];
        nameTextField.text = self.usernameTextField.text;
        [alert show];
#elif TARGET_IPHONE_SIMULATOR
        [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
#endif
         */
        [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
    }
}

//是否使用ip
- (IBAction)useIpAction:(id)sender
{
//    UISwitch *ipSwitch = (UISwitch *)sender;
//    [[EMClient sharedClient].options setEnableDnsConfig:ipSwitch.isOn];
}

//判断账号和密码是否为空
- (BOOL)isEmpty{
    BOOL ret = NO;
    NSString *username = _usernameTextField.text;
    NSString *password = _passwordTextField.text;
    if (username.length == 0 || password.length == 0) {
        ret = YES;
        [EMAlertView showAlertWithTitle:NSLocalizedString(@"prompt", @"Prompt")
                                message:NSLocalizedString(@"login.inputNameAndPswd", @"Please enter username and password")
                        completionBlock:nil
                      cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                      otherButtonTitles:nil];
    }
    
    return ret;
}


#pragma  mark - TextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == _usernameTextField) {
        _passwordTextField.text = @"";
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_usernameTextField resignFirstResponder];
        [_passwordTextField becomeFirstResponder];
    } else if (textField == _passwordTextField) {
        [_passwordTextField resignFirstResponder];
        [self doLogin:nil];
    }
    return YES;
}

#pragma  mark - private
- (void)saveLastLoginUsername
{
    NSString *username = [[EMClient sharedClient] currentUsername];
    if (username && username.length > 0) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:username forKey:[NSString stringWithFormat:@"em_lastLogin_username"]];
        [ud synchronize];
    }
}

- (NSString*)lastLoginUsername
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *username = [ud objectForKey:[NSString stringWithFormat:@"em_lastLogin_username"]];
    if (username && username.length > 0) {
        return username;
    }
    return nil;
}

@end

