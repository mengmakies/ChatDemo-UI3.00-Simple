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

#import "ChatroomDetailViewController.h"
#import <Hyphenate/EMChatroom.h>
#import "ContactView.h"
#import <Hyphenate/EMCursorResult.h>

#import "EMChatroomAdminsViewController.h"
#import "EMChatroomMembersViewController.h"
#import "EMChatroomBansViewController.h"
#import "EMChatroomMutesViewController.h"

#pragma mark - ChatGroupDetailViewController

#define kColOfRow 5
#define kContactSize 60
#define ALERTVIEW_CHANGEOWNER 100

@interface ChatroomDetailViewController ()<UIAlertViewDelegate>

@property (strong, nonatomic) EMChatroom *chatroom;

@property (strong, nonatomic) UIView *footerView;
@property (strong, nonatomic) UIButton *leaveButton;
@property (strong, nonatomic) UIButton *destroyButton;

@end

@implementation ChatroomDetailViewController

- (instancetype)initWithChatroomId:(NSString *)chatroomId
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _chatroom = [EMChatroom chatroomWithId:chatroomId];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Chatroom Info";
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:@"UpdateChatroomDetail" object:nil];
    
    self.tableView.tableFooterView = self.footerView;

    [self fetchChatroomInfo];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *)footerView
{
    if (_footerView == nil) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 120)];
        _footerView.backgroundColor = [UIColor clearColor];
        
        _destroyButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 40, _footerView.frame.size.width - 40, 40)];
        _destroyButton.accessibilityIdentifier = @"leave";
        [_destroyButton setTitle:NSLocalizedString(@"chatroom.destroy", @"dissolution of the group") forState:UIControlStateNormal];
        [_destroyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_destroyButton addTarget:self action:@selector(destroyAction) forControlEvents:UIControlEventTouchUpInside];
        [_destroyButton setBackgroundColor: [UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
        
        _leaveButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 40, _footerView.frame.size.width - 40, 40)];
        _leaveButton.accessibilityIdentifier = @"leave";
        [_leaveButton setTitle:NSLocalizedString(@"chatroom.leave", @"quit the group") forState:UIControlStateNormal];
        [_leaveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_leaveButton addTarget:self action:@selector(leaveAction) forControlEvents:UIControlEventTouchUpInside];
        [_leaveButton setBackgroundColor:[UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
        [_footerView addSubview:_leaveButton];
    }
    
    return _footerView;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.chatroom.permissionType == EMChatroomPermissionTypeOwner || self.chatroom.permissionType == EMChatroomPermissionTypeAdmin) {
        return 8;
    }
    else {
        return 6;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedString(@"chatroom.id", @"chatroom Id");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = _chatroom.chatroomId;
    }
    else if (indexPath.row == 1)
    {
        cell.textLabel.text = NSLocalizedString(@"chatroom.description", @"description");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = _chatroom.description;
    }
    else if (indexPath.row == 2)
    {
        cell.textLabel.text = NSLocalizedString(@"chatroom.occupantCount", @"members count");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i / %i", (int)_chatroom.occupantsCount, (int)_chatroom.maxOccupantsCount];
    }
    else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"group.owner", @"Owner");
        
        cell.detailTextLabel.text = self.chatroom.owner;
        
        if (self.chatroom.permissionType == EMChatroomPermissionTypeOwner) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"group.admins", @"Admins");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", (int)[self.chatroom.adminList count]];
    }
    else if (indexPath.row == 5) {
        cell.textLabel.text = NSLocalizedString(@"chatroom.onlineMembers", @"Online Members");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = @(self.chatroom.occupantsCount).stringValue;
    }
    else if (indexPath.row == 6) {
        cell.textLabel.text = NSLocalizedString(@"group.mutes", @"Mutes");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 7) {
        cell.textLabel.text = NSLocalizedString(@"title.groupBlackList", @"Black list");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    
    if (indexPath.row == 3) { //群主转换
        if (self.chatroom.permissionType == EMChatroomPermissionTypeOwner) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"group.changeOwner", @"Change Owner") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            alert.tag = ALERTVIEW_CHANGEOWNER;
            
            UITextField *textField = [alert textFieldAtIndex:0];
            textField.text = self.chatroom.owner;
            
            [alert show];
        }
    }
    else if (indexPath.row == 4) { //展示群管理员
        EMChatroomAdminsViewController *adminController = [[EMChatroomAdminsViewController alloc] initWithChatroom:self.chatroom];
        [self.navigationController pushViewController:adminController animated:YES];
    }
    else if (indexPath.row == 5) { //展示群成员
        EMChatroomMembersViewController *membersController = [[EMChatroomMembersViewController alloc] initWithChatroom:self.chatroom];
        [self.navigationController pushViewController:membersController animated:YES];
    }
    else if (indexPath.row == 6) { //展示被禁言列表
        EMChatroomMutesViewController *mutesController = [[EMChatroomMutesViewController alloc] initWithChatroom:self.chatroom];
        [self.navigationController pushViewController:mutesController animated:YES];
    }
    else if (indexPath.row == 7) { //展示黑名单
        EMChatroomBansViewController *bansController = [[EMChatroomBansViewController alloc] initWithChatroom:self.chatroom];
        [self.navigationController pushViewController:bansController animated:YES];
    }
}

#pragma mark - UIAlertViewDelegate

//弹出提示的代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView cancelButtonIndex] == buttonIndex) {
        return;
    }
    
    if (alertView.tag == ALERTVIEW_CHANGEOWNER) {
        //获取文本输入框
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *newOwner = textField.text;
        if ([newOwner length] > 0) {
            EMError *error = nil;
            [self showHudInView:self.view hint:@"Hold on ..."];
            [[EMClient sharedClient].roomManager updateChatroomOwner:self.chatroom.chatroomId newOwner:newOwner error:&error];
            [self hideHud];
            if (error) {
                [self showHint:NSLocalizedString(@"group.changeOwnerFail", @"Failed to change owner")];
            } else {
                [self.tableView reloadData];
            }
        }
        
    }
}

#pragma mark - action

- (void)updateUI:(NSNotification *)aNotif
{
    id obj = aNotif.object;
    if (obj && [obj isKindOfClass:[EMChatroom class]]) {
        self.chatroom = (EMChatroom *)obj;
        [self reloadDataSource];
    }
}

- (void)leaveAction
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"chatroom.leave", @"leave the chatroom")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = nil;
        [[EMClient sharedClient].roomManager leaveChatroom:weakSelf.chatroom.chatroomId error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (error) {
                [weakSelf showHint:NSLocalizedString(@"chatroom.leaveFail", @"leave the chatroom failure")];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitChat" object:nil];
            }
        });
    });
}

- (void)destroyAction
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"chatroom.destroy", @"destroy the chatroom")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = [[EMClient sharedClient].roomManager destroyChatroom:weakSelf.chatroom.chatroomId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (error) {
                [weakSelf showHint:NSLocalizedString(@"chatroom.destroyFail", @"destroy the chatroom failure")];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitChat" object:weakSelf.chatroom.chatroomId];
            }
        });
    });
}

#pragma mark - data

- (void)fetchChatroomInfo
{
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    __weak typeof(self) weakSelf = self;
    [[EMClient sharedClient].roomManager getChatroomSpecificationFromServerWithId:_chatroom.chatroomId completion:^(EMChatroom *aChatroom, EMError *aError) {
        __strong ChatroomDetailViewController *strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf hideHud];
            if (!aError) {
                strongSelf.chatroom = aChatroom;
                [strongSelf reloadDataSource];
            }
            else {
                [strongSelf showHint:NSLocalizedString(@"chatroom.fetchInfoFail", @"failed to get the chatroom details, please try again later")];
            }
        }
    }];
}

- (void)reloadDataSource
{
    if (self.chatroom.permissionType == EMGroupPermissionTypeOwner) {
        [self.leaveButton removeFromSuperview];
        [self.footerView addSubview:self.destroyButton];
    } else {
        [self.destroyButton removeFromSuperview];
        [self.footerView addSubview:self.leaveButton];
    }
    
    [self.tableView reloadData];
    [self hideHud];
}

@end
