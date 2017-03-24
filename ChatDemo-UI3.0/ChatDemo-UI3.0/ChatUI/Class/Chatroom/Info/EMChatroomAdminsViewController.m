//
//  EMChatroomAdminsViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 05/01/2017.
//  Copyright © 2017 XieYajie. All rights reserved.
//

#import "EMChatroomAdminsViewController.h"

@interface EMChatroomAdminsViewController ()<UIActionSheetDelegate, EaseUserCellDelegate>

@property (nonatomic, strong) EMChatroom *chatroom;
@property (nonatomic, strong) NSIndexPath *currentLongPressIndex;

@end

@implementation EMChatroomAdminsViewController

- (instancetype)initWithChatroom:(EMChatroom *)aChatroom
{
    self = [super init];
    if (self) {
        self.chatroom = aChatroom;
        [self.dataArray addObjectsFromArray:self.chatroom.adminList];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"chatroom.admins", @"Admin List");
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    self.showRefreshHeader = YES;
    [self.tableView reloadData];
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
    NSString *CellIdentifier = @"ChatroomOccupantCell";
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
            weakSelf.chatroom = [[EMClient sharedClient].roomManager removeAdmin:userName fromChatroom:weakSelf.chatroom.chatroomId error:&error];
        } else if (buttonIndex == 1) { //加入黑名单
            weakSelf.chatroom = [[EMClient sharedClient].roomManager blockMembers:@[userName] fromChatroom:weakSelf.chatroom.chatroomId error:&error];
        } else if (buttonIndex == 2) {  //禁言
            weakSelf.chatroom = [[EMClient sharedClient].roomManager muteMembers:@[userName] muteMilliseconds:-1 fromChatroom:weakSelf.chatroom.chatroomId error:&error];
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
    if (self.chatroom.permissionType != EMChatroomPermissionTypeOwner) {
        return;
    }
    
    self.currentLongPressIndex = indexPath;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"group.removeAdmin", @"Remove from Admin"), NSLocalizedString(@"friend.block", @"add to black list"), NSLocalizedString(@"group.toMute", @"Mute"), nil];
    [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    __weak typeof(self) weakSelf = self;
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
        EMError *error = nil;
        EMChatroom *chatroom = [[EMClient sharedClient].roomManager getChatroomSpecificationFromServerWithId:weakSelf.chatroom.chatroomId error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
        });
        
        [weakSelf tableViewDidFinishTriggerHeader:YES reload:NO];
        if (!error) {
            weakSelf.chatroom = chatroom;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.dataArray removeAllObjects];
                [weakSelf.dataArray addObjectsFromArray:weakSelf.chatroom.adminList];
                [weakSelf.tableView reloadData];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showHint:NSLocalizedString(@"group.fetchInfoFail", @"failed to get the group details, please try again later")];
            });
        }
    });
}

@end
