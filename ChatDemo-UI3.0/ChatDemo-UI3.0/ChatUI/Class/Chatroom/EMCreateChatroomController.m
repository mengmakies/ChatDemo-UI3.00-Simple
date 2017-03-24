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

#import "EMCreateChatroomController.h"

#import "ContactSelectionViewController.h"
#import "EMTextView.h"

@interface EMCreateChatroomController ()<UITextFieldDelegate, UITextViewDelegate, EMChooseViewDelegate>

@property (strong, nonatomic) UIView *switchView;
@property (strong, nonatomic) UIBarButtonItem *rightItem;
@property (strong, nonatomic) UITextField *textField;
@property (strong, nonatomic) EMTextView *textView;

@end

@implementation EMCreateChatroomController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    self.title = NSLocalizedString(@"title.createChatroom", @"Create a chatroom");
    self.view.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
    
//    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
//    addButton.accessibilityIdentifier = @"add_member";
//    addButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
//    [addButton setTitle:NSLocalizedString(@"group.create.addOccupant", @"add members") forState:UIControlStateNormal];
//    [addButton setTitleColor:[UIColor colorWithRed:32 / 255.0 green:134 / 255.0 blue:158 / 255.0 alpha:1.0] forState:UIControlStateNormal];
//    [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
//    [addButton addTarget:self action:@selector(addContacts:) forControlEvents:UIControlEventTouchUpInside];
//    _rightItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
//    [self.navigationItem setRightBarButtonItem:_rightItem];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    doneButton.accessibilityIdentifier = @"done";
    [doneButton setTitle:@"完成" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithCustomView:doneButton];
    [self.navigationItem setRightBarButtonItem:doneItem];
    
    [self.view addSubview:self.textField];
    [self.view addSubview:self.textView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getter

- (UITextField *)textField
{
    if (_textField == nil) {
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 300, 40)];
        _textField.accessibilityIdentifier = @"chatroom_name";
        _textField.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _textField.layer.borderWidth = 0.5;
        _textField.layer.cornerRadius = 3;
        _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 30)];
        _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _textField.font = [UIFont systemFontOfSize:15.0];
        _textField.backgroundColor = [UIColor whiteColor];
        _textField.placeholder = NSLocalizedString(@"chatroom.create.inputName", @"Please input the chatroom name");
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.delegate = self;
    }
    
    return _textField;
}

- (EMTextView *)textView
{
    if (_textView == nil) {
        _textView = [[EMTextView alloc] initWithFrame:CGRectMake(10, 70, 300, 80)];
        _textView.accessibilityIdentifier = @"chatroom_subject";
        _textView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _textView.layer.borderWidth = 0.5;
        _textView.layer.cornerRadius = 3;
        _textView.font = [UIFont systemFontOfSize:14.0];
        _textView.backgroundColor = [UIColor whiteColor];
        _textView.placeholder = NSLocalizedString(@"chatroom.create.inputDescribe", @"Please enter a chatroom description");
        _textView.returnKeyType = UIReturnKeyDone;
        _textView.delegate = self;
    }
    
    return _textView;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        
        
        [textView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - EMChooseViewDelegate

- (BOOL)viewController:(EMChooseViewController *)viewController didFinishSelectedSources:(NSArray *)selectedSources
{
    NSInteger maxUsersCount = 200;
    if ([selectedSources count] > (maxUsersCount - 1)) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"group.maxUserCount", nil) message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
        
        return NO;
    }
    
    [self showHudInView:self.view hint:NSLocalizedString(@"chatroom.create.ongoing", @"Create a chatroom...")];
    
    NSMutableArray *source = [NSMutableArray array];
    for (NSString *username in selectedSources) {
        [source addObject:username];
    }
    
    __weak EMCreateChatroomController *weakSelf = self;
    NSString *username = [[EMClient sharedClient] currentUsername];
    NSString *messageStr = [NSString stringWithFormat:NSLocalizedString(@"chatroom.somebodyInvite", @"%@ invite you to join chatroom \'%@\'"), username, self.textField.text];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        EMChatroom *chatroom = [[EMClient sharedClient].roomManager createChatroomWithSubject:self.textField.text description:self.textView.text invitees:source message:messageStr maxMembersCount:maxUsersCount error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (chatroom && !error) {
                [weakSelf showHint:NSLocalizedString(@"chatroom.create.success", @"create chatroom success")];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
            else{
                [weakSelf showHint:NSLocalizedString(@"chatroom.create.fail", @"Failed to create a chatroom, please operate again")];
            }
        });
    });
    return YES;
}

#pragma mark - action

- (void)doneAction:(id)sender
{
    [self showHudInView:self.view hint:NSLocalizedString(@"chatroom.create.ongoing", @"Create a chatroom...")];
    
    __weak EMCreateChatroomController *weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        EMChatroom *chatroom = [[EMClient sharedClient].roomManager createChatroomWithSubject:self.textField.text description:self.textView.text invitees:nil message:nil maxMembersCount:100 error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideHud];
            if (chatroom && !error) {
                [weakSelf showHint:NSLocalizedString(@"chatroom.create.success", @"create chatroom success")];
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
            else{
                [weakSelf showHint:NSLocalizedString(@"chatroom.create.fail", @"Failed to create a chatroom, please operate again")];
            }
        });
    });
}

- (void)addContacts:(id)sender
{
    if (self.textField.text.length == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"prompt", @"Prompt") message:NSLocalizedString(@"chatroom.create.inputName", @"please input the chtroom name") delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", @"OK") otherButtonTitles:nil, nil];
        [alertView show];
        return;
    }
    
    [self.view endEditing:YES];
    
    ContactSelectionViewController *selectionController = [[ContactSelectionViewController alloc] init];
    selectionController.delegate = self;
    [self.navigationController pushViewController:selectionController animated:YES];
}

@end
