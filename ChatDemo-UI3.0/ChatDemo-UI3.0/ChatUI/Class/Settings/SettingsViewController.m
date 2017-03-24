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

#import "SettingsViewController.h"

#import "ApplyViewController.h"
#import "PushNotificationViewController.h"
#import "BlackListViewController.h"
#import "DebugViewController.h"
#import "EditNicknameViewController.h"
#import "UserProfileEditViewController.h"
#import "RedpacketViewControl.h"

#if DEMO_CALL == 1
#import "CallSettingViewController.h"
#endif

@interface SettingsViewController ()

@property (strong, nonatomic) UIView *footerView;

@property (strong, nonatomic) UISwitch *autoLoginSwitch;
@property (strong, nonatomic) UISwitch *delConversationSwitch;
@property (strong, nonatomic) UISwitch *groupInviteSwitch;
@property (strong, nonatomic) UISwitch *sortMethodSwitch;

@end

@implementation SettingsViewController

@synthesize autoLoginSwitch = _autoLoginSwitch;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"title.setting", @"Setting");
    self.view.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
    self.navigationItem.backBarButtonItem.accessibilityIdentifier = @"back";
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = self.footerView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - getter

- (UISwitch *)autoLoginSwitch
{
    if (_autoLoginSwitch == nil) {
        _autoLoginSwitch = [[UISwitch alloc] init];
        [_autoLoginSwitch addTarget:self action:@selector(autoLoginChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    return _autoLoginSwitch;
}

- (UISwitch *)delConversationSwitch
{
    if (!_delConversationSwitch)
    {
        _delConversationSwitch = [[UISwitch alloc] init];
        _delConversationSwitch.on = [[EMClient sharedClient].options isDeleteMessagesWhenExitGroup];
        [_delConversationSwitch addTarget:self action:@selector(delConversationChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _delConversationSwitch;
}

- (UISwitch *)groupInviteSwitch
{
    if (!_groupInviteSwitch)
    {
        _groupInviteSwitch = [[UISwitch alloc] init];
        _groupInviteSwitch.on = [[EMClient sharedClient].options isAutoAcceptGroupInvitation];
        [_groupInviteSwitch addTarget:self action:@selector(groupInviteChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _groupInviteSwitch;
}

- (UISwitch *)sortMethodSwitch
{
    if (_sortMethodSwitch == nil) {
        _sortMethodSwitch = [[UISwitch alloc] init];
        [_sortMethodSwitch addTarget:self action:@selector(sortMethodChanged:) forControlEvents:UIControlEventValueChanged];
    }

    return _sortMethodSwitch;
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#ifdef REDPACKET_AVALABLE
    return 2;
#endif
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#ifdef REDPACKET_AVALABLE
    if (section == 0) {
        return 1;
    }
#endif
    
#if DEMO_CALL == 1
    return 10;
#endif

    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
    } else {
        [cell.contentView.subviews enumerateObjectsUsingBlock:^(UIView * subView, NSUInteger idx, BOOL *stop) {
            [subView removeFromSuperview];
        }];
    }

#ifdef REDPACKET_AVALABLE
    if (indexPath.section == 0) {
        cell.textLabel.text = @"零钱";
    }else if (indexPath.section == 1) {
#else
    if (indexPath.section == 0) {
#endif
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"setting.autoLogin", @"automatic login");
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.autoLoginSwitch.frame = CGRectMake(self.tableView.frame.size.width - (self.autoLoginSwitch.frame.size.width + 10), (cell.contentView.frame.size.height - self.autoLoginSwitch.frame.size.height) / 2, self.autoLoginSwitch.frame.size.width, self.autoLoginSwitch.frame.size.height);
            [cell.contentView addSubview:self.autoLoginSwitch];
        } else if (indexPath.row == 1)
        {
            cell.textLabel.text = NSLocalizedString(@"title.apnsSetting", @"Apns Settings");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2)
        {
            cell.textLabel.text = NSLocalizedString(@"title.buddyBlock", @"Black List");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 3)
        {
            cell.textLabel.text = NSLocalizedString(@"title.debug", @"Debug");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 4){
            cell.textLabel.text = NSLocalizedString(@"setting.deleteConWhenLeave", @"Delete conversation when leave a group");
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.delConversationSwitch.frame = CGRectMake(self.tableView.frame.size.width - (self.delConversationSwitch.frame.size.width + 10), (cell.contentView.frame.size.height - self.delConversationSwitch.frame.size.height) / 2, self.delConversationSwitch.frame.size.width, self.delConversationSwitch.frame.size.height);
            [cell.contentView addSubview:self.delConversationSwitch];
        } else if (indexPath.row == 5) {
            cell.textLabel.text = NSLocalizedString(@"setting.autoAcceptGrupInvite", @"Auto accept group invite");
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.groupInviteSwitch.frame = CGRectMake(self.tableView.frame.size.width - (self.groupInviteSwitch.frame.size.width + 10), (cell.contentView.frame.size.height - self.groupInviteSwitch.frame.size.height) / 2, self.groupInviteSwitch.frame.size.width, self.groupInviteSwitch.frame.size.height);
            [cell.contentView addSubview:self.groupInviteSwitch];
        } else if (indexPath.row == 6) {
            cell.textLabel.text = NSLocalizedString(@"setting.iospushname", @"iOS push nickname");
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 7) {
            cell.textLabel.text = NSLocalizedString(@"setting.personalInfo", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 8) {
            cell.textLabel.text = NSLocalizedString(@"setting.sortbyservertime", @"Sort message by server time");
            cell.accessoryType = UITableViewCellAccessoryNone;
            self.sortMethodSwitch.frame = CGRectMake(self.tableView.frame.size.width - (self.sortMethodSwitch.frame.size.width + 10), (cell.contentView.frame.size.height - self.sortMethodSwitch.frame.size.height) / 2, self.sortMethodSwitch.frame.size.width, self.sortMethodSwitch.frame.size.height);
            [cell.contentView addSubview:self.sortMethodSwitch];
        } else if (indexPath.row == 9) {
            cell.textLabel.text = @"清除缓存（昵称和头像）";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }else if (indexPath.row == 10) {
            cell.textLabel.text = NSLocalizedString(@"setting.call", nil);
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
#ifdef REDPACKET_AVALABLE
    if (indexPath.section == 0) {
        UIViewController *controller = [RedpacketViewControl changeMoneyController];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:nav animated:YES completion:nil];
        return;
    }
#endif
    
    if (indexPath.row == 1) {
        PushNotificationViewController *pushController = [[PushNotificationViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:pushController animated:YES];
    }
    else if (indexPath.row == 2)
    {
        BlackListViewController *blackController = [[BlackListViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:blackController animated:YES];
    }
    else if (indexPath.row == 3)
    {
        DebugViewController *debugController = [[DebugViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:debugController animated:YES];
    } else if (indexPath.row == 6) {
        EditNicknameViewController *editName = [[EditNicknameViewController alloc] initWithNibName:nil bundle:nil];
        [self.navigationController pushViewController:editName animated:YES];
    } else if (indexPath.row == 7){
        UserProfileEditViewController *userProfile = [[UserProfileEditViewController alloc] initWithStyle:UITableViewStylePlain];
        [self.navigationController pushViewController:userProfile animated:YES];
        
    } else if (indexPath.row == 9) {
        [UserCacheManager clearTableData];
        [UserWebManager clearCache];
        [self showHint:@"已经清除用户本地头像和昵称~"];
    }else if (indexPath.row == 10) {
#if DEMO_CALL == 1
        CallSettingViewController *callSettingController = [[CallSettingViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController pushViewController:callSettingController animated:YES];
#endif
    }
}

#pragma mark - getter

- (UIView *)footerView
{
    if (_footerView == nil) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
        _footerView.backgroundColor = [UIColor clearColor];
        
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 0, _footerView.frame.size.width - 10, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        [_footerView addSubview:line];
        
        UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, _footerView.frame.size.width - 20, 45)];
        logoutButton.accessibilityIdentifier = @"logoff";
        [logoutButton setBackgroundColor:RGBACOLOR(0xfe, 0x64, 0x50, 1)];
        NSString *username = [[EMClient sharedClient] currentUsername];
        NSString *logoutButtonTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"setting.loginUser", @"log out(%@)"), username];
        [logoutButton setTitle:logoutButtonTitle forState:UIControlStateNormal];
        [logoutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [logoutButton addTarget:self action:@selector(logoutAction) forControlEvents:UIControlEventTouchUpInside];
        [_footerView addSubview:logoutButton];
    }
    
    return _footerView;
}

#pragma mark - action

- (void)autoLoginChanged:(UISwitch *)autoSwitch
{
    [[EMClient sharedClient].options setIsAutoLogin:autoSwitch.isOn];
}

- (void)delConversationChanged:(UISwitch *)control
{
    [[EMClient sharedClient].options setIsDeleteMessagesWhenExitGroup:control.on];
}
    
- (void)groupInviteChanged:(UISwitch *)control
{
    [[EMClient sharedClient].options setIsAutoAcceptGroupInvitation:control.on];
}

- (void)sortMethodChanged:(UISwitch *)control
{
    [[EMClient sharedClient].options setSortMessageByServerTime:control.on];
}

- (void)refreshConfig
{
    [self.autoLoginSwitch setOn:[[EMClient sharedClient].options isAutoLogin] animated:NO];
    [self.sortMethodSwitch setOn:[[EMClient sharedClient].options sortMessageByServerTime] animated:NO];
    
    [self.tableView reloadData];
}

- (void)logoutAction
{
    __weak SettingsViewController *weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"setting.logoutOngoing", @"loging out...")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient] logout:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (error != nil) {
                [weakSelf showHint:error.errorDescription];
            }
            else{
                [[ApplyViewController shareController] clear];
                [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
            }
        });
    });
}
 
@end
