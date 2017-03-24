//
//  CallSettingViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 06/12/2016.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import "CallSettingViewController.h"

#import "DemoCallManager.h"
#import "CallResolutionViewController.h"

#define FIXED_BITRATE_ALERTVIEW_TAG 100
#define AUTO_MAXRATE_ALERTVIEW_TAG 99
#define AUTO_MINKBPS_ALERTVIEW_TAG 98

@interface CallSettingViewController ()<UIAlertViewDelegate>

@property (nonatomic, strong) UISwitch *fixedSwitch;
@property (strong, nonatomic) UISwitch *showCallInfoSwitch;
@property (strong, nonatomic) UISwitch *callPushSwitch;

@end

@implementation CallSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.title = NSLocalizedString(@"setting.call", nil);
    
    self.fixedSwitch = [[UISwitch alloc] init];
    [self.fixedSwitch addTarget:self action:@selector(fixedSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
    CGRect frame = self.fixedSwitch.frame;
    frame.origin.x = self.view.frame.size.width - 10 - frame.size.width;
    frame.origin.y = 10;
    self.fixedSwitch.frame = frame;
    
    self.showCallInfoSwitch = [[UISwitch alloc] init];
    self.showCallInfoSwitch.frame = frame;
    self.showCallInfoSwitch.on = [[[NSUserDefaults standardUserDefaults] objectForKey:@"showCallInfo"] boolValue];
    [self.showCallInfoSwitch addTarget:self action:@selector(showCallInfoChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.callPushSwitch = [[UISwitch alloc] init];
    self.callPushSwitch.frame = frame;
    [self.callPushSwitch addTarget:self action:@selector(callPushChanged:) forControlEvents:UIControlEventValueChanged];
    
    EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
    [self.fixedSwitch setOn:options.isFixedVideoResolution animated:NO];
    [self.callPushSwitch setOn:options.isSendPushIfOffline animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 2;
    }
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"setting.call.push", nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell.contentView addSubview:self.callPushSwitch];
        } else if (indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"setting.call.showInfo", nil);
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell.contentView addSubview:self.showCallInfoSwitch];
        }
        
    } else {
        if (self.fixedSwitch.isOn) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.fixedResolution", nil);
                [cell.contentView addSubview:self.fixedSwitch];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.bitrate", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row == 2) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.resolution", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        } else {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.autoResolution", nil);
                [cell.contentView addSubview:self.fixedSwitch];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.maxFramerate", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else if (indexPath.row == 2) {
                cell.textLabel.text = NSLocalizedString(@"setting.call.minKbps", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        if (self.fixedSwitch.isOn) {
            if (indexPath.row == 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"setting.setBitrate", @"Set Bitrate") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                alert.tag = FIXED_BITRATE_ALERTVIEW_TAG;
        
                UITextField *textField = [alert textFieldAtIndex:0];
                EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
                textField.text = [NSString stringWithFormat:@"%ld", options.videoKbps];
        
                [alert show];
            } else if (indexPath.row == 2) {
                CallResolutionViewController *resoulutionController = [[CallResolutionViewController alloc] init];
                [self.navigationController pushViewController:resoulutionController animated:YES];
            }
        } else {
            if (indexPath.row == 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"setting.call.maxFramerate", @"Video max framerate") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                alert.tag = AUTO_MAXRATE_ALERTVIEW_TAG;
                
                UITextField *textField = [alert textFieldAtIndex:0];
                EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
                textField.text = [NSString stringWithFormat:@"%d", options.maxVideoFrameRate];
                
                [alert show];
            } else if (indexPath.row == 2) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"setting.call.minKbps", @"Video min kbps") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
                [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                alert.tag = AUTO_MINKBPS_ALERTVIEW_TAG;
                
                UITextField *textField = [alert textFieldAtIndex:0];
                EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
                textField.text = [NSString stringWithFormat:@"%d", options.minVideoKbps];
                
                [alert show];
            }
        }
    }
}

#pragma mark - UIAlertViewDelegate

//弹出提示的代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
#if DEMO_CALL == 1
    if ([alertView cancelButtonIndex] != buttonIndex) {
        //获取文本输入框
        UITextField *textField = [alertView textFieldAtIndex:0];
        int value = 0;
        if ([textField.text length] > 0) {
            value = [textField.text intValue];
        }

        if (alertView.tag == FIXED_BITRATE_ALERTVIEW_TAG) {
            if (value >= 150 && value <= 1000) {
                EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
                options.videoKbps = value;
                [[DemoCallManager sharedManager] saveCallOptions];
            } else {
                [self showHint:NSLocalizedString(@"setting.call.bitrateTips", @"Set Bitrate should be 150-1000")];
            }
        } else if (alertView.tag == AUTO_MAXRATE_ALERTVIEW_TAG) {
            EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
            options.maxVideoFrameRate = value;
            [[DemoCallManager sharedManager] saveCallOptions];
        } else if (alertView.tag == AUTO_MINKBPS_ALERTVIEW_TAG) {
            EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
            options.minVideoKbps = value;
            [[DemoCallManager sharedManager] saveCallOptions];
        }
    }
#endif
}

#pragma mark - Action

- (void)fixedSwitchValueChanged:(UISwitch *)control
{
    [self.tableView reloadData];
    
#if DEMO_CALL == 1
    EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
    options.isFixedVideoResolution = control.on;
    [[DemoCallManager sharedManager] saveCallOptions];
#endif
}

- (void)showCallInfoChanged:(UISwitch *)control
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:control.isOn] forKey:@"showCallInfo"];
    [userDefaults synchronize];
}

- (void)callPushChanged:(UISwitch *)control
{
#if DEMO_CALL == 1
    EMCallOptions *options = [[EMClient sharedClient].callManager getCallOptions];
    options.isSendPushIfOffline = control.on;
    [[DemoCallManager sharedManager] saveCallOptions];
#endif
}

@end
