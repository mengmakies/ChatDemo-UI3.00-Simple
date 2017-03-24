//
//  EMChatroomMembersViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 06/01/2017.
//  Copyright © 2017 XieYajie. All rights reserved.
//

#import "EMChatroomMembersViewController.h"

@interface EMChatroomMembersViewController ()<UIActionSheetDelegate, EaseUserCellDelegate>

@property (nonatomic, strong) EMChatroom *chatroom;
@property (nonatomic, strong) NSIndexPath *currentLongPressIndex;
@property (nonatomic, strong) NSString *cursor;

@end

@implementation EMChatroomMembersViewController

- (instancetype)initWithChatroom:(EMChatroom *)aChatroom
{
    self = [super init];
    if (self) {
        self.chatroom = aChatroom;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"chatroom.members", @"Member List");
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    self.showRefreshHeader = YES;
    [self tableViewDidTriggerHeaderRefresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"GroupOccupantCell";
    EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.delegate = self;
    }
    
    cell.avatarView.image = [UIImage imageNamed:@"EaseUIResource.bundle/user"];
    cell.titleLabel.text = [self.dataArray objectAtIndex:indexPath.row];
    cell.indexPath = indexPath;
    
    return cell;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex || _currentLongPressIndex == nil) {
        return;
    }
    
    NSIndexPath *indexPath = _currentLongPressIndex;
    NSString *userName = [self.dataArray objectAtIndex:indexPath.row];
    _currentLongPressIndex = nil;
    
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"wait", @"Pleae wait...")];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        if (buttonIndex == 0) { //移除
            weakSelf.chatroom = [[EMClient sharedClient].roomManager removeMembers:@[userName] fromChatroom:weakSelf.chatroom.chatroomId error:&error];
        } else if (buttonIndex == 1) { //加入黑名单
            weakSelf.chatroom = [[EMClient sharedClient].roomManager blockMembers:@[userName] fromChatroom:weakSelf.chatroom.chatroomId error:&error];
        } else if (buttonIndex == 2) {  //禁言
            weakSelf.chatroom = [[EMClient sharedClient].roomManager muteMembers:@[userName] muteMilliseconds:-1 fromChatroom:weakSelf.chatroom.chatroomId error:&error];
        } else if (buttonIndex == 3) {  //升为管理员
            weakSelf.chatroom = [[EMClient sharedClient].roomManager addAdmin:userName toChatroom:weakSelf.chatroom.chatroomId error:&error];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (!error) {
                if (buttonIndex != 2) {
                    [weakSelf.dataArray removeObject:userName];
                    [weakSelf.tableView reloadData];
                } else {
                    [weakSelf showHint:@"禁言成功"];
                }
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateChatroomDetail" object:weakSelf.chatroom];
            }
            else {
                [weakSelf showHint:error.errorDescription];
            }
        });
    });
}

#pragma mark - EaseUserCellDelegate

- (void)cellLongPressAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.chatroom.permissionType != EMChatroomPermissionTypeOwner && self.chatroom.permissionType != EMChatroomPermissionTypeAdmin) {
        return;
    }
    
    self.currentLongPressIndex = indexPath;
    UIActionSheet *actionSheet = nil;
    if (self.chatroom.permissionType == EMChatroomPermissionTypeOwner) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") destructiveButtonTitle:nil  otherButtonTitles:NSLocalizedString(@"group.removeMember", @"Remove from group"), NSLocalizedString(@"friend.block", @"Add to black list"), NSLocalizedString(@"group.toMute", @"Mute"), NSLocalizedString(@"group.addAdmin", @"Add to admin"), nil];
    } else if (self.chatroom.permissionType == EMChatroomPermissionTypeAdmin) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") destructiveButtonTitle:nil  otherButtonTitles:NSLocalizedString(@"group.removeMember", @"Remove from group"), NSLocalizedString(@"friend.block", @"Add to black list"), NSLocalizedString(@"group.toMute", @"Mute"), nil];
    }
    
    if (actionSheet) {
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
    }
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    self.cursor = @"";
    [self fetchMembersWithPage:self.page isHeader:YES];
}

- (void)tableViewDidTriggerFooterRefresh
{
    [self fetchMembersWithPage:self.page isHeader:NO];
}

- (void)fetchMembersWithPage:(NSInteger)aPage
                    isHeader:(BOOL)aIsHeader
{
    NSInteger pageSize = 50;
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    [[EMClient sharedClient].roomManager getChatroomMemberListFromServerWithId:self.chatroom.chatroomId cursor:self.cursor pageSize:pageSize completion:^(EMCursorResult *aResult, EMError *aError) {
        weakSelf.cursor = aResult.cursor;
        [weakSelf hideHud];
        [weakSelf tableViewDidFinishTriggerHeader:aIsHeader reload:NO];
        if (!aError) {
            if (aIsHeader) {
                [weakSelf.dataArray removeAllObjects];
            }

            [weakSelf.dataArray addObjectsFromArray:aResult.list];
            [weakSelf.tableView reloadData];
        } else {
            [weakSelf showHint:NSLocalizedString(@"group.fetchInfoFail", @"failed to get the group details, please try again later")];
        }
        
        if ([aResult.list count] == 0) {
            self.showRefreshFooter = NO;
        } else {
            self.showRefreshFooter = YES;
        }
    }];
}

@end
