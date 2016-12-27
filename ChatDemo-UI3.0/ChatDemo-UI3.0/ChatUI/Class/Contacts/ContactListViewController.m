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

#import "ContactListViewController.h"

#import "ChatViewController.h"
#import "RobotListViewController.h"
#import "ChatroomListViewController.h"
#import "AddFriendViewController.h"
#import "ApplyViewController.h"
#import "RealtimeSearchUtil.h"
#import "RedPacketChatViewController.h"

#import "BaseTableViewCell.h"
#import "UIViewController+SearchController.h"


@implementation NSString (search)

//根据用户昵称进行搜索
- (NSString*)showName
{
    return [UserCacheManager getNickById:self];
}

@end

@interface ContactListViewController ()<UISearchBarDelegate, UIActionSheetDelegate, EaseUserCellDelegate, EMSearchControllerDelegate>
{
    NSIndexPath *_currentLongPressIndex;
}

@property (strong, nonatomic) NSMutableArray *sectionTitles;
@property (strong, nonatomic) NSMutableArray *contactsSource;

@property (nonatomic) NSInteger unapplyCount;

@property (nonatomic) NSIndexPath *indexPath;

@end

@implementation ContactListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.showRefreshHeader = YES;
    
    _contactsSource = [NSMutableArray array];
    _sectionTitles = [NSMutableArray array];
    
    // 环信UIdemo中有用到Parse, 加载用户好友个人信息
//    [[UserProfileManager sharedInstance] loadUserProfileInBackgroundWithBuddy:self.contactsSource saveToLoacal:YES completion:NULL];
    
    [self setupSearchController];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadApplyView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getter

- (NSArray *)rightItems
{
    if (_rightItems == nil) {
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [addButton setImage:[UIImage imageNamed:@"addContact.png"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addContactAction) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
        _rightItems = @[addItem];
    }
    
    return _rightItems;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.dataArray count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 3;
    }
    
    return [[self.dataArray objectAtIndex:(section - 1)] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            NSString *CellIdentifier = @"addFriend";
            EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            cell.avatarView.image = [UIImage imageNamed:@"newFriends"];
            cell.titleLabel.text = NSLocalizedString(@"title.apply", @"Application and notification");
            cell.avatarView.badge = self.unapplyCount;
            return cell;
        }
        
        NSString *CellIdentifier = @"commonCell";
        EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        if (indexPath.row == 1) {
            cell.avatarView.image = [UIImage imageNamed:@"EaseUIResource.bundle/group"];
            cell.titleLabel.text = NSLocalizedString(@"title.group", @"Group");
        }
        else if (indexPath.row == 2) {
            cell.avatarView.image = [UIImage imageNamed:@"EaseUIResource.bundle/group"];
            cell.titleLabel.text = NSLocalizedString(@"title.chatroomlist",@"chatroom list");
        }
        else if (indexPath.row == 3) {
            cell.avatarView.image = [UIImage imageNamed:@"EaseUIResource.bundle/group"];
            cell.titleLabel.text = NSLocalizedString(@"title.robotlist",@"robot list");
        }
        return cell;
    }
    else{
        NSString *CellIdentifier = [EaseUserCell cellIdentifierWithModel:nil];
        EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Configure the cell...
        if (cell == nil) {
            cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSArray *userSection = [self.dataArray objectAtIndex:(indexPath.section - 1)];
        EaseUserModel *model = [userSection objectAtIndex:indexPath.row];
        UserCacheInfo *user = [UserCacheManager getById:model.buddy];
        if (user) {
            model.nickname= user.NickName;
            model.avatarURLPath = user.AvatarUrl;
        }
        cell.indexPath = indexPath;
        cell.delegate = self;
        cell.model = model;
        
        return cell;
    }}

#pragma mark - Table view delegate

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionTitles;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0;
    }
    else{
        return 22;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return nil;
    }
    
    UIView *contentView = [[UIView alloc] init];
    [contentView setBackgroundColor:[UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 22)];
    label.backgroundColor = [UIColor clearColor];
    [label setText:[self.sectionTitles objectAtIndex:(section - 1)]];
    [contentView addSubview:label];
    return contentView;
}
         
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (section == 0) {
        if (row == 0) {
            [self.navigationController pushViewController:[ApplyViewController shareController] animated:YES];
        }
        else if (row == 1)
        {
//            if (_groupController == nil) {
//                _groupController = [[GroupListViewController alloc] initWithStyle:UITableViewStylePlain];
//            }
//            else{
//                [_groupController reloadDataSource];
//            }
            GroupListViewController *groupController = [[GroupListViewController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:groupController animated:YES];
        }
        else if (row == 2)
        {
            ChatroomListViewController *controller = [[ChatroomListViewController alloc] initWithStyle:UITableViewStylePlain];
            [self.navigationController pushViewController:controller animated:YES];
        }
        else if (row == 3) {
            RobotListViewController *robot = [[RobotListViewController alloc] init];
            [self.navigationController pushViewController:robot animated:YES];
        }
    }
    else{
        EaseUserModel *model = [[self.dataArray objectAtIndex:(section - 1)] objectAtIndex:row];
        UIViewController *chatController = nil;
#ifdef REDPACKET_AVALABLE
        chatController = [[RedPacketChatViewController alloc] initWithConversationChatter:model.buddy conversationType:EMConversationTypeChat];
#else
        chatController = [[ChatViewController alloc] initWithConversationChatter:model.buddy conversationType:EMConversationTypeChat];
#endif
        chatController.title = model.nickname.length > 0 ? model.nickname : model.buddy;
        [self.navigationController pushViewController:chatController animated:YES];
    }
}
                                                       
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}
                                                       
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *loginUsername = [[EMClient sharedClient] currentUsername];
        EaseUserModel *model = [[self.dataArray objectAtIndex:(indexPath.section - 1)] objectAtIndex:indexPath.row];
        if ([model.buddy isEqualToString:loginUsername]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"friend.notDeleteSelf", @"can't delete self") delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
            [alertView show];
            
            return;
        }
        
        self.indexPath = indexPath;
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"delete conversation", @"Delete conversation") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (self.indexPath == nil)
    {
        return;
    }
    
    NSIndexPath *indexPath = self.indexPath;
    EaseUserModel *model = [[self.dataArray objectAtIndex:(indexPath.section - 1)] objectAtIndex:indexPath.row];
    self.indexPath = nil;
    
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        EMError *error = [[EMClient sharedClient].contactManager deleteContact:model.buddy isDeleteConversation:NO];
        if (!error) {
            [self.tableView beginUpdates];
            [[self.dataArray objectAtIndex:(indexPath.section - 1)] removeObjectAtIndex:indexPath.row];
            [self.contactsSource removeObject:model.buddy];
            [self.tableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else{
            [self showHint:[NSString stringWithFormat:NSLocalizedString(@"deleteFailed", @"Delete failed:%@"), error.errorDescription]];
            [self.tableView reloadData];
        }
    }
    else
    {
        EMError *error = [[EMClient sharedClient].contactManager deleteContact:model.buddy isDeleteConversation:YES];
        if (!error) {
            [[EMClient sharedClient].chatManager deleteConversation:model.buddy isDeleteMessages:YES completion:nil];
            
            [self.tableView beginUpdates];
            [[self.dataArray objectAtIndex:(indexPath.section - 1)] removeObjectAtIndex:indexPath.row];
            [self.contactsSource removeObject:model.buddy];
            [self.tableView  deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView endUpdates];
        }
        else{
            [self showHint:[NSString stringWithFormat:NSLocalizedString(@"deleteFailed", @"Delete failed:%@"), error.errorDescription]];
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex || _currentLongPressIndex == nil) {
        return;
    }
    
    NSIndexPath *indexPath = _currentLongPressIndex;
    EaseUserModel *model = [[self.dataArray objectAtIndex:(indexPath.section - 1)] objectAtIndex:indexPath.row];
    _currentLongPressIndex = nil;
    
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"wait", @"Pleae wait...")];
    EMError *error = [[EMClient sharedClient].contactManager addUserToBlackList:model.buddy relationshipBoth:YES];
    [self hideHud];
    if (!error) {
        //由于加入黑名单成功后会刷新黑名单，所以此处不需要再更改好友列表
        [self reloadDataSource];
    }
    else {
        [self showHint:error.errorDescription];
    }
}
                                                       
#pragma mark - EaseUserCellDelegate
                                                       
- (void)cellLongPressAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row >= 1) {
        return;
    }
    
    _currentLongPressIndex = indexPath;
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") destructiveButtonTitle:NSLocalizedString(@"friend.block", @"join the blacklist") otherButtonTitles:nil, nil];
    [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
}
                                               
#pragma mark - EMSearchControllerDelegate     
                                                       
- (void)cancelButtonClicked
{
    [[RealtimeSearchUtil currentUtil] realtimeSearchStop];
}
                                               
- (void)searchButtonClickedWithString:(NSString *)aString
{
    __weak typeof(self) weakSelf = self;
    [[RealtimeSearchUtil currentUtil] realtimeSearchWithSource:self.contactsSource searchText:aString collationStringSelector:@selector(showName) resultBlock:^(NSArray *results) {
        if (results) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.resultController.displaySource removeAllObjects];
                [weakSelf.resultController.displaySource addObjectsFromArray:results];
                [weakSelf.resultController.tableView reloadData];
            });
        }
    }];
}

#pragma mark - action

- (void)addContactAction
{
    AddFriendViewController *addController = [[AddFriendViewController alloc] init];
    [self.navigationController pushViewController:addController animated:YES];
}

#pragma mark - private
                                                       
- (void)setupSearchController
{
    [self enableSearchController];
    
    __weak ContactListViewController *weakSelf = self;
    [self.resultController setCellForRowAtIndexPathCompletion:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *CellIdentifier = @"BaseTableViewCell";
        BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        // Configure the cell...
        if (cell == nil) {
            cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSString *buddy = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        cell.imageView.image = [UIImage imageNamed:@"chatListCellHead"];
        cell.textLabel.text = buddy;
        cell.username = buddy;
        
        return cell;
    }];
    
    [self.resultController setHeightForRowAtIndexPathCompletion:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
        return 50;
    }];
    
    [self.resultController setDidSelectRowAtIndexPathCompletion:^(UITableView *tableView, NSIndexPath *indexPath) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSString *buddy = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        [weakSelf.searchController.searchBar endEditing:YES];
        
#ifdef REDPACKET_AVALABLE
        RedPacketChatViewController *chatVC = [[RedPacketChatViewController alloc] initWithConversationChatter:buddy conversationType:EMConversationTypeChat];
#else
        ChatViewController *chatVC = [[ChatViewController alloc] initWithConversationChatter:buddy
                                     conversationType:EMConversationTypeChat];
#endif
        chatVC.title = [UserCacheManager getNickById:buddy];
        [weakSelf.navigationController pushViewController:chatVC animated:YES];
                                               
        [weakSelf cancelSearch];
    }];
        
    UISearchBar *searchBar = self.searchController.searchBar;
    [self.view addSubview:searchBar];
    [searchBar sizeToFit];
    self.tableView.frame = CGRectMake(0, searchBar.frame.size.height, self.view.frame.size.width,self.view.frame.size.height - searchBar.frame.size.height);

}

- (void)_sortDataArray:(NSArray *)buddyList
{
    [self.dataArray removeAllObjects];
    [self.sectionTitles removeAllObjects];
    NSMutableArray *contactsSource = [NSMutableArray array];
    
    //从获取的数据中剔除黑名单中的好友
    NSArray *blockList = [[EMClient sharedClient].contactManager getBlackList];
    for (NSString *buddy in buddyList) {
        if (![blockList containsObject:buddy]) {
            [contactsSource addObject:buddy];
        }
    }
    
    //建立索引的核心, 返回27，是a－z和＃
    UILocalizedIndexedCollation *indexCollation = [UILocalizedIndexedCollation currentCollation];
    [self.sectionTitles addObjectsFromArray:[indexCollation sectionTitles]];
    
    NSInteger highSection = [self.sectionTitles count];
    NSMutableArray *sortedArray = [NSMutableArray arrayWithCapacity:highSection];
    for (int i = 0; i < highSection; i++) {
        NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:1];
        [sortedArray addObject:sectionArray];
    }
    
    //按首字母分组
    for (NSString *buddy in contactsSource) {
        EaseUserModel *model = [[EaseUserModel alloc] initWithBuddy:buddy];
        if (model) {
            model.avatarImage = [UIImage imageNamed:@"chatListCellHead"];
            model.nickname = [UserCacheManager getNickById:buddy];
            
            NSString *firstLetter = [EaseChineseToPinyin pinyinFromChineseString:[UserCacheManager getNickById:buddy]];
            NSInteger section;
            if (firstLetter.length > 0) {
                section = [indexCollation sectionForObject:[firstLetter substringToIndex:1] collationStringSelector:@selector(uppercaseString)];
            } else {
                section = [sortedArray count] - 1;
            }
            
            NSMutableArray *array = [sortedArray objectAtIndex:section];
            [array addObject:model];
        }
    }
    
    //每个section内的数组排序
    for (int i = 0; i < [sortedArray count]; i++) {
        NSArray *array = [[sortedArray objectAtIndex:i] sortedArrayUsingComparator:^NSComparisonResult(EaseUserModel *obj1, EaseUserModel *obj2) {
            NSString *firstLetter1 = [EaseChineseToPinyin pinyinFromChineseString:obj1.buddy];
            firstLetter1 = [[firstLetter1 substringToIndex:1] uppercaseString];
            
            NSString *firstLetter2 = [EaseChineseToPinyin pinyinFromChineseString:obj2.buddy];
            firstLetter2 = [[firstLetter2 substringToIndex:1] uppercaseString];
            
            return [firstLetter1 caseInsensitiveCompare:firstLetter2];
        }];
        
        
        [sortedArray replaceObjectAtIndex:i withObject:[NSMutableArray arrayWithArray:array]];
    }
    
    //去掉空的section
    for (NSInteger i = [sortedArray count] - 1; i >= 0; i--) {
        NSArray *array = [sortedArray objectAtIndex:i];
        if ([array count] == 0) {
            [sortedArray removeObjectAtIndex:i];
            [self.sectionTitles removeObjectAtIndex:i];
        }
    }
    
    [self.dataArray addObjectsFromArray:sortedArray];
    [self.tableView reloadData];
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        NSArray *buddyList = [[EMClient sharedClient].contactManager getContactsFromServerWithError:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideHud];
        });
        if (!error) {
            [[EMClient sharedClient].contactManager getBlackListFromServerWithError:&error];
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.contactsSource removeAllObjects];
                    
                    for (NSInteger i = (buddyList.count - 1); i >= 0; i--) {
                        NSString *username = [buddyList objectAtIndex:i];
                        [weakself.contactsSource addObject:username];
                    }
                    [weakself _sortDataArray:self.contactsSource];
                });
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself showHint:NSLocalizedString(@"loadDataFailed", @"Load data failed.")];
                [weakself reloadDataSource];
            });
        }
        [weakself tableViewDidFinishTriggerHeader:YES reload:NO];
    });
}

#pragma mark - public

- (void)reloadDataSource
{
    [self.dataArray removeAllObjects];
    [self.contactsSource removeAllObjects];
    
    NSArray *buddyList = [[EMClient sharedClient].contactManager getContacts];
    
    for (NSString *buddy in buddyList) {
        [self.contactsSource addObject:buddy];
    }
    [self _sortDataArray:self.contactsSource];
    
    [self.tableView reloadData];
}

- (void)reloadApplyView
{
    NSInteger count = [[[ApplyViewController shareController] dataSource] count];
    self.unapplyCount = count;
    [self.tableView reloadData];
}

- (void)reloadGroupView
{
    [self reloadApplyView];
    
    if (_groupController) {
        [_groupController tableViewDidTriggerHeaderRefresh];
    }
}

- (void)addFriendAction
{
    AddFriendViewController *addController = [[AddFriendViewController alloc] init];
    [self.navigationController pushViewController:addController animated:YES];
}

@end
