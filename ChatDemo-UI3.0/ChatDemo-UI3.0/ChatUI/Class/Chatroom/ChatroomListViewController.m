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

#import "ChatroomListViewController.h"

#import "ChatViewController.h"
#import "RealtimeSearchUtil.h"
#import <Hyphenate/EMCursorResult.h>
#import "BaseTableViewCell.h"

#import "UIViewController+SearchController.h"
#import "EMCreateChatroomController.h"

#define FetchChatroomPageSize   20

@interface ChatroomListViewController ()<EMSearchControllerDelegate, EMChatroomManagerDelegate>

@end

@implementation ChatroomListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.title = NSLocalizedString(@"title.chatroom",@"chatroom");
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [addButton setTitle:@"创建" forState:UIControlStateNormal];
    [addButton addTarget:self action:@selector(createChatroomAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    [self.navigationItem setRightBarButtonItem:addItem];

    self.page = 1;
    self.showRefreshHeader = YES;
    [self setupSearchController];
    
    [[EMClient sharedClient].roomManager addDelegate:self delegateQueue:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeChatroom:) name:@"ExitChat" object:nil];

    [self tableViewDidTriggerHeaderRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    //由于离开页面时可能有大量聊天室对象需要释放，所以把释放操作放到一个独立线程
    if ([self.dataArray count])
    {
        NSMutableArray *chatrooms = self.dataArray;
        self.dataArray = nil;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [chatrooms removeAllObjects];
        });
    }
    [[EMClient sharedClient].roomManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return [self.dataArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroupCell";
    BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    EMChatroom *chatroom = [self.dataArray objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"groupPublicHeader"];
    if ([chatroom.subject length]) {
        cell.textLabel.text = chatroom.subject;
    }
    else {
        cell.textLabel.text = chatroom.chatroomId;
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
    
    EMChatroom *myChatroom = [self.dataArray objectAtIndex:indexPath.row];
    ChatViewController *chatController = [[ChatViewController alloc] initWithConversationChatter:myChatroom.chatroomId conversationType:EMConversationTypeChatRoom];
    chatController.title = myChatroom.subject;
    [self.navigationController pushViewController:chatController animated:YES];
}

#pragma mark - EMChatroomManagerDelegate

- (void)didReceiveKickedFromChatroom:(EMChatroom *)aChatroom
                              reason:(EMChatroomBeKickedReason)aReason
{
    //    if (aReason != EMChatroomBeKickedReasonDestroyed)
    //    {
    //        return;
    //    }
    //
    //    [self.dataSource enumerateObjectsUsingBlock:^(EMChatroom *chatroom, NSUInteger idx, BOOL *stop){
    //        if ([aChatroom.chatroomId isEqualToString:chatroom.chatroomId])
    //        {
    //            [self.dataSource removeObjectAtIndex:idx];
    //            *stop = YES;
    //        }
    //    }];
    //    [self.tableView reloadData];
}

#pragma mark - EMSearchControllerDelegate

- (void)willSearchBegin
{
    [self tableViewDidFinishTriggerHeader:YES reload:NO];
}

- (void)cancelButtonClicked
{
    [[RealtimeSearchUtil currentUtil] realtimeSearchStop];
}

- (void)didSearchFinish
{
    if ([self.resultController.displaySource count]) {
        return ;
    }
    
    UISearchBar *searchBar = self.searchController.searchBar;
    __block EMChatroom *foundChatroom = nil;
    [self.dataArray enumerateObjectsUsingBlock:^(EMChatroom *chatroom, NSUInteger idx, BOOL *stop){
        if ([chatroom.chatroomId isEqualToString:searchBar.text])
        {
            foundChatroom = chatroom;
            *stop = YES;
        }
    }];
    
    if (foundChatroom)
    {
        [self.resultController.displaySource removeAllObjects];
        [self.resultController.displaySource addObject:foundChatroom];
        [self.resultController.tableView reloadData];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [self showHudInView:self.view hint:NSLocalizedString(@"searching", @"Searching")];
        dispatch_async(dispatch_get_main_queue(), ^{
            EMError *error = nil;
            EMChatroom *chatroom = [[EMClient sharedClient].roomManager fetchChatroomInfo:searchBar.text includeMembersList:false error:&error];
            [weakSelf hideHud];
            
            if (weakSelf)
            {
                ChatroomListViewController *strongSelf = weakSelf;
                if (!error) {
                    [weakSelf.resultController.displaySource removeAllObjects];
                    [weakSelf.resultController.displaySource addObject:chatroom];
                    [strongSelf.resultController.tableView reloadData];
                }
                else
                {
                    [strongSelf showHint:NSLocalizedString(@"notFound", @"Can't found")];
                }
            }
        });
    }
}

- (void)searchTextChangeWithString:(NSString *)aString
{
    __weak typeof(self) weakSelf = self;
    [[RealtimeSearchUtil currentUtil] realtimeSearchWithSource:self.dataArray searchText:aString collationStringSelector:@selector(subject) resultBlock:^(NSArray *results) {
        if (results) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.resultController.displaySource removeAllObjects];
                [weakSelf.resultController.displaySource addObjectsFromArray:results];
                [weakSelf.resultController.tableView reloadData];
            });
        }
    }];
}

#pragma mark - private

- (void)setupSearchController
{
    [self enableSearchController];
    
    __weak ChatroomListViewController *weakSelf = self;
    [self.resultController setCellForRowAtIndexPathCompletion:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *CellIdentifier = @"ContactListCell";
        BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        // Configure the cell...
        if (cell == nil) {
            cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

        EMChatroom *chatroom = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        NSString *imageName =  @"groupPublicHeader";
        cell.imageView.image = [UIImage imageNamed:imageName];
        cell.textLabel.text = chatroom.subject;

        return cell;
    }];

    [self.resultController setHeightForRowAtIndexPathCompletion:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
        return 50;
    }];

    [self.resultController setDidSelectRowAtIndexPathCompletion:^(UITableView *tableView, NSIndexPath *indexPath) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [weakSelf.searchController.searchBar endEditing:YES];

        EMChatroom *myChatroom = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        ChatViewController *chatController = [[ChatViewController alloc] initWithConversationChatter:myChatroom.chatroomId conversationType:EMConversationTypeChatRoom];
        chatController.title = myChatroom.subject;
        [weakSelf.navigationController pushViewController:chatController animated:YES];
        
        [weakSelf cancelSearch];
    }];
    
    UISearchBar *searchBar = self.searchController.searchBar;
    self.tableView.tableHeaderView = searchBar;
}

- (void)createChatroomAction
{
    EMCreateChatroomController *createRoomController = [[EMCreateChatroomController alloc] init];
    [self.navigationController pushViewController:createRoomController animated:YES];
}

#pragma mark - Action

- (void)removeChatroom:(NSNotification *)aNotif
{
    id obj = aNotif.object;
    if (obj && [obj isKindOfClass:[NSString class]]) {
        NSString *roomId = (NSString *)obj;
        if ([roomId length] == 0) {
            return;
        }
        
        for (EMChatroom *room in self.dataArray) {
            if ([room.chatroomId isEqualToString:roomId]) {
                [self.dataArray removeObject:room];
                [self.tableView reloadData];
                break;
            }
        }
    }
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    self.page = 1;
    [self fetchChatRoomsWithPage:self.page isHeader:YES];
}

- (void)tableViewDidTriggerFooterRefresh
{
    self.page += 1;
    [self fetchChatRoomsWithPage:self.page isHeader:NO];
}

- (void)fetchChatRoomsWithPage:(NSInteger)aPage
                      isHeader:(BOOL)aIsHeader
{
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        EMPageResult *result = [[EMClient sharedClient].roomManager getChatroomsFromServerWithPage:aPage pageSize:FetchChatroomPageSize error:&error];
        if (weakSelf)
        {
            ChatroomListViewController *strongSelf = weakSelf;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf hideHud];
                
                if (!error)
                {
                    if (aIsHeader) {
                        NSMutableArray *oldChatrooms = [self.dataArray mutableCopy];
                        [self.dataArray removeAllObjects];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [oldChatrooms removeAllObjects];
                        });
                    }
                    
                    [strongSelf.dataArray addObjectsFromArray:result.list];
                    [strongSelf.tableView reloadData];
                    if (result.count > 0) {
                        strongSelf.showRefreshFooter = YES;
                    } else {
                        strongSelf.showRefreshFooter = NO;
                    }
                    
                    [strongSelf tableViewDidFinishTriggerHeader:aIsHeader reload:NO];
                }
            });
        }
    });
}

@end
