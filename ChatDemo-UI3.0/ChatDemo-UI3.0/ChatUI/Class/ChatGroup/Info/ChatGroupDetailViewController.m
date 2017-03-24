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

#import "ChatGroupDetailViewController.h"

#import "ContactSelectionViewController.h"
#import "GroupSettingViewController.h"
#import <Hyphenate/EMGroup.h>
#import "ContactView.h"
#import "GroupSubjectChangingViewController.h"
#import "SearchMessageViewController.h"
#import "EMGroupAdminsViewController.h"
#import "EMGroupMembersViewController.h"
#import "EMGroupMutesViewController.h"
#import "EMGroupBansViewController.h"

#pragma mark - ChatGroupDetailViewController

#define kColOfRow 5
#define kContactSize 60

#define ALERTVIEW_CHANGEOWNER 100

@interface ChatGroupDetailViewController ()<EMGroupManagerDelegate, EMChooseViewDelegate, UIAlertViewDelegate>

- (void)unregisterNotifications;
- (void)registerNotifications;

@property (strong, nonatomic) EMGroup *chatGroup;
@property (strong, nonatomic) UIBarButtonItem *addMemberItem;

@property (strong, nonatomic) UIView *footerView;
@property (strong, nonatomic) UIButton *clearButton;
@property (strong, nonatomic) UIButton *exitButton;
@property (strong, nonatomic) UIButton *dissolveButton;
@property (strong, nonatomic) UIButton *configureButton;

@property (strong, nonatomic) ContactView *selectedContact;

- (void)dissolveAction;
- (void)clearAction;
- (void)exitAction;
- (void)configureAction;

@end

@implementation ChatGroupDetailViewController

- (instancetype)initWithGroup:(EMGroup *)chatGroup
{
    self = [super init];
    if (self) {
        // Custom initialization
        _chatGroup = chatGroup;
    }
    return self;
}

- (instancetype)initWithGroupId:(NSString *)chatGroupId
{
    EMGroup *chatGroup = nil;
    NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
    for (EMGroup *group in groupArray) {
        if ([group.groupId isEqualToString:chatGroupId]) {
            chatGroup = group;
            break;
        }
    }
    
    if (chatGroup == nil) {
        chatGroup = [EMGroup groupWithId:chatGroupId];
    }
    
    self = [self initWithGroup:chatGroup];
    if (self) {
        //
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Group Info";
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    addButton.accessibilityIdentifier = @"add";
    [addButton setTitle:@"+ 成员" forState:UIControlStateNormal];
    [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(addMemberButtonAction) forControlEvents:UIControlEventTouchUpInside];
    self.addMemberItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    
    self.showRefreshHeader = YES;
    self.tableView.tableFooterView = self.footerView;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI:) name:@"UpdateGroupDetail" object:nil];
    [self registerNotifications];
    
    [self fetchGroupInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    [self unregisterNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerNotifications {
    [self unregisterNotifications];
    [[EMClient sharedClient].groupManager addDelegate:self delegateQueue:nil];
}

- (void)unregisterNotifications {
    [[EMClient sharedClient].groupManager removeDelegate:self];
}

#pragma mark - getter

- (UIButton *)clearButton
{
    if (_clearButton == nil) {
        _clearButton = [[UIButton alloc] init];
        _clearButton.accessibilityIdentifier = @"clear_message";
        [_clearButton setTitle:NSLocalizedString(@"group.removeAllMessages", @"remove all messages") forState:UIControlStateNormal];
        [_clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearAction) forControlEvents:UIControlEventTouchUpInside];
        [_clearButton setBackgroundColor:[UIColor colorWithRed:87 / 255.0 green:186 / 255.0 blue:205 / 255.0 alpha:1.0]];
    }
    
    return _clearButton;
}

- (UIButton *)dissolveButton
{
    if (_dissolveButton == nil) {
        _dissolveButton = [[UIButton alloc] init];
        _dissolveButton.accessibilityIdentifier = @"leave";
        [_dissolveButton setTitle:NSLocalizedString(@"group.destroy", @"dissolution of the group") forState:UIControlStateNormal];
        [_dissolveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_dissolveButton addTarget:self action:@selector(dissolveAction) forControlEvents:UIControlEventTouchUpInside];
        [_dissolveButton setBackgroundColor: [UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
    }
    
    return _dissolveButton;
}

- (UIButton *)exitButton
{
    if (_exitButton == nil) {
        _exitButton = [[UIButton alloc] init];
        _exitButton.accessibilityIdentifier = @"leave";
        [_exitButton setTitle:NSLocalizedString(@"group.leave", @"quit the group") forState:UIControlStateNormal];
        [_exitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_exitButton addTarget:self action:@selector(exitAction) forControlEvents:UIControlEventTouchUpInside];
        [_exitButton setBackgroundColor:[UIColor colorWithRed:191 / 255.0 green:48 / 255.0 blue:49 / 255.0 alpha:1.0]];
    }
    
    return _exitButton;
}

- (UIView *)footerView
{
    if (_footerView == nil) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 160)];
        _footerView.backgroundColor = [UIColor clearColor];
        
        self.clearButton.frame = CGRectMake(20, 40, _footerView.frame.size.width - 40, 35);
        [_footerView addSubview:self.clearButton];
        
        self.dissolveButton.frame = CGRectMake(20, CGRectGetMaxY(self.clearButton.frame) + 30, _footerView.frame.size.width - 40, 35);
        
        self.exitButton.frame = CGRectMake(20, CGRectGetMaxY(self.clearButton.frame) + 30, _footerView.frame.size.width - 40, 35);
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
    if (self.chatGroup.permissionType == EMGroupPermissionTypeOwner || self.chatGroup.permissionType == EMGroupPermissionTypeAdmin) {
        return 9;
    }
    else {
        return 7;
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
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"group.id", @"group ID");
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.detailTextLabel.text = _chatGroup.groupId;
    }
    else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"title.groupSetting", @"Group Setting");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"title.groupSubjectChanging", @"Change group name");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 3) {
        cell.textLabel.text = NSLocalizedString(@"title.groupSearchMessage", @"Search Message from History");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 4) {
        cell.textLabel.text = NSLocalizedString(@"group.owner", @"Owner");
        
        cell.detailTextLabel.text = self.chatGroup.owner;
        
        if (self.chatGroup.permissionType == EMGroupPermissionTypeOwner) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else if (indexPath.row == 5) {
        cell.textLabel.text = NSLocalizedString(@"group.admins", @"Admins");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i", (int)[self.chatGroup.adminList count]];
    }
    else if (indexPath.row == 6) {
        cell.textLabel.text = NSLocalizedString(@"group.members", @"Members");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%i / %i", (int)(self.chatGroup.occupantsCount - 1 - [self.chatGroup.adminList count]), (int)self.chatGroup.setting.maxUsersCount];
        NSLog([NSString stringWithFormat:@"111111=========%ld", (long)self.chatGroup.occupantsCount]);
    }
    else if (indexPath.row == 7) {
        cell.textLabel.text = NSLocalizedString(@"group.mutes", @"Mutes");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (indexPath.row == 8) {
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
    
    if (indexPath.row == 1) {
        GroupSettingViewController *settingController = [[GroupSettingViewController alloc] initWithGroup:_chatGroup];
        [self.navigationController pushViewController:settingController animated:YES];
    }
    else if (indexPath.row == 2)
    {
        GroupSubjectChangingViewController *changingController = [[GroupSubjectChangingViewController alloc] initWithGroup:_chatGroup];
        [self.navigationController pushViewController:changingController animated:YES];
    }
    else if (indexPath.row == 3) {
        SearchMessageViewController *searchMsgController = [[SearchMessageViewController alloc] initWithConversationId:_chatGroup.groupId conversationType:EMConversationTypeGroupChat];
        [self.navigationController pushViewController:searchMsgController animated:YES];
    }
    else if (indexPath.row == 4) { //群主转换
        if (self.chatGroup.permissionType == EMGroupPermissionTypeOwner) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"group.changeOwner", @"Change Owner") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
            [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
            alert.tag = ALERTVIEW_CHANGEOWNER;
            
            UITextField *textField = [alert textFieldAtIndex:0];
            textField.text = self.chatGroup.owner;
            
            [alert show];
        }
    }
    else if (indexPath.row == 5) { //展示群管理员
        EMGroupAdminsViewController *adminController = [[EMGroupAdminsViewController alloc] initWithGroup:self.chatGroup];
        [self.navigationController pushViewController:adminController animated:YES];
    }
    else if (indexPath.row == 6) { //展示群成员
        EMGroupMembersViewController *membersController = [[EMGroupMembersViewController alloc] initWithGroup:self.chatGroup];
        [self.navigationController pushViewController:membersController animated:YES];
    }
    else if (indexPath.row == 7) { //展示被禁言列表
        EMGroupMutesViewController *mutesController = [[EMGroupMutesViewController alloc] initWithGroup:self.chatGroup];
        [self.navigationController pushViewController:mutesController animated:YES];
    }
    else if (indexPath.row == 8) { //展示黑名单
        EMGroupBansViewController *bansController = [[EMGroupBansViewController alloc] initWithGroup:self.chatGroup];
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
            self.chatGroup = [[EMClient sharedClient].groupManager updateGroupOwner:self.chatGroup.groupId newOwner:newOwner error:&error];
            [self hideHud];
            if (error) {
                [self showHint:NSLocalizedString(@"group.changeOwnerFail", @"Failed to change owner")];
            } else {
                [self.tableView reloadData];
            }
        }
        
    }
}

#pragma mark - EMChooseViewDelegate

- (BOOL)viewController:(EMChooseViewController *)viewController didFinishSelectedSources:(NSArray *)selectedSources
{
    NSInteger maxUsersCount = self.chatGroup.setting.maxUsersCount;
    if (([selectedSources count] + self.chatGroup.membersCount) > maxUsersCount) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"group.maxUserCount", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
        
        return NO;
    }
    
    [self showHudInView:self.view hint:NSLocalizedString(@"group.addingOccupant", @"add a group member...")];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *source = [NSMutableArray array];
        for (NSString *username in selectedSources) {
            [source addObject:username];
        }
        
        NSString *username = [[EMClient sharedClient] currentUsername];
        NSString *messageStr = [NSString stringWithFormat:NSLocalizedString(@"group.somebodyInvite", @"%@ invite you to join group \'%@\'"), username, weakSelf.chatGroup.subject];
        EMError *error = nil;
        weakSelf.chatGroup = [[EMClient sharedClient].groupManager addOccupants:source toGroup:weakSelf.chatGroup.groupId welcomeMessage:messageStr error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [weakSelf reloadDataSource];
            }
            else {
                [weakSelf hideHud];
                [weakSelf showHint:error.errorDescription];
            }
        
        });
    });
    
    return YES;
}

#pragma mark - EMGroupManagerDelegate

- (void)groupInvitationDidAccept:(EMGroup *)aGroup
                         invitee:(NSString *)aInvitee
{
    if ([aGroup.groupId isEqualToString:self.chatGroup.groupId]) {
        [self fetchGroupInfo];
    }
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    [self fetchGroupInfo];
}

- (void)fetchGroupInfo
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = nil;
        EMGroup *group = [[EMClient sharedClient].groupManager getGroupSpecificationFromServerWithId:weakSelf.chatGroup.groupId error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            [weakSelf tableViewDidFinishTriggerHeader:YES reload:NO];
        });
        
        if (!error) {
            weakSelf.chatGroup = group;
            EMConversation *conversation = [[EMClient sharedClient].chatManager getConversation:group.groupId type:EMConversationTypeGroupChat createIfNotExist:YES];
            if ([group.groupId isEqualToString:conversation.conversationId]) {
                NSMutableDictionary *ext = [NSMutableDictionary dictionaryWithDictionary:conversation.ext];
                [ext setObject:group.subject forKey:@"subject"];
                [ext setObject:[NSNumber numberWithBool:group.isPublic] forKey:@"isPublic"];
                conversation.ext = ext;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf reloadDataSource];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showHint:NSLocalizedString(@"group.fetchInfoFail", @"failed to get the group details, please try again later")];
            });
        }
    });
}

- (void)reloadDataSource
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.chatGroup.permissionType == EMGroupPermissionTypeOwner || self.chatGroup.permissionType == EMGroupPermissionTypeAdmin || self.chatGroup.setting.style == EMGroupStylePrivateMemberCanInvite) {
            self.navigationItem.rightBarButtonItem = self.addMemberItem;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
        
        [self.tableView reloadData];
        [self refreshFooterView];
        [self hideHud];
    });
}

- (void)refreshFooterView
{
    if (self.chatGroup.permissionType == EMGroupPermissionTypeOwner) {
        [_exitButton removeFromSuperview];
        [_footerView addSubview:self.dissolveButton];
    }
    else{
        [_dissolveButton removeFromSuperview];
        [_footerView addSubview:self.exitButton];
    }
}

#pragma mark - action

- (void)updateUI:(NSNotification *)aNotif
{
    id obj = aNotif.object;
    if (obj && [obj isKindOfClass:[EMGroup class]]) {
        self.chatGroup = (EMGroup *)obj;
        [self reloadDataSource];
    }
}

- (void)addMemberButtonAction
{
    NSMutableArray *occupants = [[NSMutableArray alloc] init];
    [occupants addObject:self.chatGroup.owner];
    [occupants addObjectsFromArray:self.chatGroup.adminList];
    [occupants addObjectsFromArray:self.chatGroup.memberList];
    ContactSelectionViewController *selectionController = [[ContactSelectionViewController alloc] initWithBlockSelectedUsernames:occupants];
    selectionController.delegate = self;
    [self.navigationController pushViewController:selectionController animated:YES];
}

//清空聊天记录
- (void)clearAction
{
    __weak typeof(self) weakSelf = self;
    [EMAlertView showAlertWithTitle:NSLocalizedString(@"prompt", @"Prompt")
                            message:NSLocalizedString(@"sureToDelete", @"please make sure to delete")
                    completionBlock:^(NSUInteger buttonIndex, EMAlertView *alertView) {
                        if (buttonIndex == 1) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveAllMessages" object:weakSelf.chatGroup.groupId];
                        }
                    } cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel")
                  otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
    
}

//解散群组
- (void)dissolveAction
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"group.destroy", @"dissolution of the group")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = [[EMClient sharedClient].groupManager destroyGroup:weakSelf.chatGroup.groupId];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (error) {
                [weakSelf showHint:NSLocalizedString(@"group.destroyFail", @"dissolution of group failure")];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitChat" object:nil];
            }
        });
    });
}

//设置群组
- (void)configureAction {
    // todo
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        [[EMClient sharedClient].groupManager ignoreGroupPush:weakSelf.chatGroup.groupId ignore:weakSelf.chatGroup.isPushNotificationEnabled];
    });
}

//退出群组
- (void)exitAction
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"group.leave", @"quit the group")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = nil;
        [[EMClient sharedClient].groupManager leaveGroup:weakSelf.chatGroup.groupId error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (error) {
                [weakSelf showHint:NSLocalizedString(@"group.leaveFail", @"exit the group failure")];
            }
            else{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ExitChat" object:nil];
            }
        });
    });
}

- (void)didIgnoreGroupPushNotification:(NSArray *)ignoredGroupList error:(EMError *)error {
    // todo
    NSLog(@"ignored group list:%@.", ignoredGroupList);
}

@end
