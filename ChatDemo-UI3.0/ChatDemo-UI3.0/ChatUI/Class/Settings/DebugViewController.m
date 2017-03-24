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

#import "DebugViewController.h"

#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MessageUI.h>

@interface DebugViewController ()<MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSString *logPath;

@end

@implementation DebugViewController

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
    
    self.title = NSLocalizedString(@"title.debug", @"Debug");
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 80)];
    footerView.backgroundColor = [UIColor clearColor];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10, 0, footerView.frame.size.width - 10, 0.5)];
        line.backgroundColor = [UIColor lightGrayColor];
        [footerView addSubview:line];
    }
    
//    UIButton *uploadLogButton = [[UIButton alloc] initWithFrame:CGRectMake(40, 20, footerView.frame.size.width - 80, 40)];
//    [uploadLogButton setBackgroundColor:[UIColor colorWithRed:87 / 255.0 green:186 / 255.0 blue:205 / 255.0 alpha:1.0]];
//    [uploadLogButton setTitle:NSLocalizedString(@"setting.uploadLog", @"upload run log") forState:UIControlStateNormal];
//    [uploadLogButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [uploadLogButton addTarget:self action:@selector(uploadLogAction) forControlEvents:UIControlEventTouchUpInside];
//    [footerView addSubview:uploadLogButton];
//    self.tableView.tableFooterView = footerView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"setting.sdkVersion", @"SDK version");
        NSString *ver = [[EMClient sharedClient] version];
        cell.detailTextLabel.text = ver;
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"setting.emailLog", @"Email send logs");
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        if ([MFMailComposeViewController canSendMail] == false) {
            return;
        }
        
        EMError *error = nil;
        [self showHudInView:self.view hint:@"获取压缩路径..."];
        __weak typeof(self) weakSelf = self;
        [[EMClient sharedClient] getLogFilesPathWithCompletion:^(NSString *aPath, EMError *aError) {
            [weakSelf hideHud];
            
            if (error == nil) {
                weakSelf.logPath = aPath;
                MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
                if(mailCompose) {
                    //设置代理
                    [mailCompose setMailComposeDelegate:self];
                    
                    //设置收件人
//                    NSArray *toAddress = [NSArray arrayWithObject:@""];
//                    [mailCompose setToRecipients:toAddress];
                    
                    //设置邮件主题
                    [mailCompose setSubject:@"这是Log文件"];
                    
                    //设置邮件内容
                    NSString *emailBody = @"测试发送log压缩文件";
                    [mailCompose setMessageBody:emailBody isHTML:NO];
                    
                    //设置邮件附件{mimeType:文件格式|fileName:文件名}
                    NSData* pData = [[NSData alloc]initWithContentsOfFile:aPath];
                    [mailCompose addAttachmentData:pData mimeType:@"" fileName:@"log.gz"];
                    
                    //设置邮件视图在当前视图上显示方式
                    [self presentViewController:mailCompose animated:YES completion:nil];
                }
            }
        }];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error
{
    NSString *msg = @"";
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            msg = @"邮件发送取消";
            break;
        case MFMailComposeResultSaved:
            msg = @"邮件保存成功";
            break;
        case MFMailComposeResultSent:
            msg = @"邮件发送成功";
            break;
        case MFMailComposeResultFailed:
            msg = @"邮件发送失败";
            break;
        default:
            break;
    }
    
    if ([msg length] > 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:self.logPath error:nil];
    self.logPath = nil;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - action

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)uploadLogAction
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[EMClient sharedClient] uploadLogToServer];
    });
}

@end
