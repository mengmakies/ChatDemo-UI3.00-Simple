//
//  EMGroupMembersViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 06/01/2017.
//  Copyright © 2017 XieYajie. All rights reserved.
//

#import "EMGroupMembersViewController.h"

@interface EMGroupMembersViewController ()<UIActionSheetDelegate, EaseUserCellDelegate>

@property (nonatomic, strong) EMGroup *group;
@property (nonatomic, strong) NSIndexPath *currentLongPressIndex;
@property (nonatomic, strong) NSString *cursor;

@end

@implementation EMGroupMembersViewController

- (instancetype)initWithGroup:(EMGroup *)aGroup
{
    self = [super init];
    if (self) {
        self.group = aGroup;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"group.members", @"Members");
    
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
            weakSelf.group = [[EMClient sharedClient].groupManager removeOccupants:@[userName] fromGroup:weakSelf.group.groupId error:&error];
        } else if (buttonIndex == 1) { //加入黑名单
            weakSelf.group = [[EMClient sharedClient].groupManager blockOccupants:@[userName] fromGroup:weakSelf.group.groupId error:&error];
        } else if (buttonIndex == 2) {  //禁言
            weakSelf.group = [[EMClient sharedClient].groupManager muteMembers:@[userName] muteMilliseconds:-1 fromGroup:weakSelf.group.groupId error:&error];
        } else if (buttonIndex == 3) {  //升为管理员
            weakSelf.group = [[EMClient sharedClient].groupManager addAdmin:userName toGroup:weakSelf.group.groupId error:&error];
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
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroupDetail" object:weakSelf.group];
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
    if (self.group.permissionType != EMGroupPermissionTypeOwner && self.group.permissionType != EMGroupPermissionTypeAdmin) {
        return;
    }
    
    self.currentLongPressIndex = indexPath;
    UIActionSheet *actionSheet = nil;
    if (self.group.permissionType == EMGroupPermissionTypeOwner) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") destructiveButtonTitle:nil  otherButtonTitles:NSLocalizedString(@"group.removeMember", @"Remove from group"), NSLocalizedString(@"friend.block", @"Add to black list"), NSLocalizedString(@"group.toMute", @"Mute"), NSLocalizedString(@"group.addAdmin", @"Add to admin"), nil];
    } else if (self.group.permissionType == EMGroupPermissionTypeAdmin) {
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
    [[EMClient sharedClient].groupManager getGroupMemberListFromServerWithId:self.group.groupId cursor:self.cursor pageSize:pageSize completion:^(EMCursorResult *aResult, EMError *aError) {
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
            weakSelf.showRefreshFooter = NO;
        } else {
            weakSelf.showRefreshFooter = YES;
        }
    }];
}

@end
