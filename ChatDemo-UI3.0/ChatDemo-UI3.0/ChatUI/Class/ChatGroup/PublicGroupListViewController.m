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

#import "PublicGroupListViewController.h"

#import "PublicGroupDetailViewController.h"
#import "RealtimeSearchUtil.h"
#import <Hyphenate/EMCursorResult.h>
#import "BaseTableViewCell.h"

#import "UIViewController+SearchController.h"

#define FetchPublicGroupsPageSize   50

@interface PublicGroupListViewController ()<EMSearchControllerDelegate>

@property (strong, nonatomic) NSMutableArray *dataSource;

@property (nonatomic, strong) NSString *cursor;

@end

@implementation PublicGroupListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _dataSource = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.title = NSLocalizedString(@"title.publicGroup", @"Public group");
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    self.showRefreshHeader = YES;
    [self setupSearchController];

    [self tableViewDidTriggerHeaderRefresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    //由于可能有大量公有群在退出页面时需要释放，所以把释放操作放到其它线程避免卡UI
    NSMutableArray *publicGroups = [self.dataSource mutableCopy];
    [self.dataSource removeAllObjects];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [publicGroups removeAllObjects];
    });
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
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroupCell";
    BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    EMGroup *group = [self.dataSource objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"groupPublicHeader"];
    if (group.subject && group.subject.length > 0) {
        cell.textLabel.text = group.subject;
    }
    else {
        cell.textLabel.text = group.groupId;
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
    
    EMGroup *group = [self.dataSource objectAtIndex:indexPath.row];
    PublicGroupDetailViewController *detailController = [[PublicGroupDetailViewController alloc] initWithGroupId:group.groupId];
    detailController.title = group.subject;
    [self.navigationController pushViewController:detailController animated:YES];
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
        return;
    }
    
    UISearchBar *searchBar = self.searchController.searchBar;
    __block EMGroup *foundGroup= nil;
    [self.dataSource enumerateObjectsUsingBlock:^(EMGroup *group, NSUInteger idx, BOOL *stop){
        if ([group.groupId isEqualToString:searchBar.text])
        {
            foundGroup = group;
            *stop = YES;
        }
    }];

    if (foundGroup)
    {
        [self.resultController.displaySource removeAllObjects];
        [self.resultController.displaySource addObject:foundGroup];
        [self.resultController.tableView reloadData];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        [self showHudInView:self.view hint:NSLocalizedString(@"searching", @"Searching")];
        dispatch_async(dispatch_get_main_queue(), ^{
            EMError *error = nil;
            EMGroup *group = [[EMClient sharedClient].groupManager searchPublicGroupWithId:searchBar.text error:&error];
            PublicGroupListViewController *strongSelf = weakSelf;
            [strongSelf hideHud];
            if (strongSelf)
            {
                if (!error) {
                    [strongSelf.resultController.displaySource removeAllObjects];
                    [strongSelf.resultController.displaySource addObject:group];
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
    [[RealtimeSearchUtil currentUtil] realtimeSearchWithSource:self.dataSource searchText:aString collationStringSelector:@selector(subject) resultBlock:^(NSArray *results) {
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
    
    __weak PublicGroupListViewController *weakSelf = self;
    [self.resultController setCellForRowAtIndexPathCompletion:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
        static NSString *CellIdentifier = @"ContactListCell";
        BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

        // Configure the cell...
        if (cell == nil) {
            cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }

        EMGroup *group = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        NSString *imageName = group.isPublic ? @"groupPublicHeader" : @"groupPrivateHeader";
        cell.imageView.image = [UIImage imageNamed:imageName];
        cell.textLabel.text = group.subject;

        return cell;
    }];

    [self.resultController setHeightForRowAtIndexPathCompletion:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
        return 50;
    }];

    [self.resultController setDidSelectRowAtIndexPathCompletion:^(UITableView *tableView, NSIndexPath *indexPath) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [weakSelf.searchController.searchBar endEditing:YES];

        EMGroup *group = [weakSelf.resultController.displaySource objectAtIndex:indexPath.row];
        PublicGroupDetailViewController *detailController = [[PublicGroupDetailViewController alloc] initWithGroupId:group.groupId];
        detailController.title = group.subject;
        [weakSelf.navigationController pushViewController:detailController animated:YES];
        
        [weakSelf cancelSearch];
    }];
    
    UISearchBar *searchBar = self.searchController.searchBar;
    self.tableView.tableHeaderView = searchBar;
}

#pragma mark - data

- (void)tableViewDidTriggerHeaderRefresh
{
    [self fetchGroups:YES];
}

- (void)tableViewDidTriggerFooterRefresh
{
    [self fetchGroups:NO];
}

- (void)fetchGroups:(BOOL)aIsHeader
{
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    
    if (aIsHeader) {
        _cursor = nil;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        EMCursorResult *result = [[EMClient sharedClient].groupManager getPublicGroupsFromServerWithCursor:weakSelf.cursor pageSize:FetchPublicGroupsPageSize error:&error];
        if (!weakSelf) {
            return ;
        }
        
        PublicGroupListViewController *strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf hideHud];
            if (error) {
                return ;
            }
            
            if (aIsHeader) {
                NSMutableArray *oldGroups = [self.dataSource mutableCopy];
                [self.dataSource removeAllObjects];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [oldGroups removeAllObjects];
                });
            }
            
            [strongSelf.dataSource addObjectsFromArray:result.list];
            [strongSelf.tableView reloadData];
            strongSelf.cursor = result.cursor;
            if ([result.cursor length] > 0) {
                strongSelf.showRefreshFooter = YES;
            } else {
                strongSelf.showRefreshFooter = NO;
            }
            
            [strongSelf tableViewDidFinishTriggerHeader:aIsHeader reload:NO];
        });
    });
}

@end
