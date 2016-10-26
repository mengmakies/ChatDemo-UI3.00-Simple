//
//  UserTableViewController.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 8/31/16.
//  Copyright © 2016 XieYajie. All rights reserved.
//

#import "UserTableViewController.h"

@interface UserTableViewController ()

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation UserTableViewController

- (instancetype)initWithDataSource:(NSArray *)aDataSource
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.dataArray = aDataSource;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    
    NSString *username = [self.dataArray objectAtIndex:indexPath.row];
    cell.textLabel.text = username;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *username = [self.dataArray objectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"selecteInviteUser" object:username];
    
    [self.navigationController popViewControllerAnimated:YES];
}
@end
