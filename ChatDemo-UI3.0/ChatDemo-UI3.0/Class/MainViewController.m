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

#import "MainViewController.h"

#import "SettingsViewController.h"
#import "ApplyViewController.h"
#import "ChatViewController.h"
#import "ConversationListController.h"
#import "ContactListViewController.h"
#import "ChatUIHelper.h"
#import "RedPacketChatViewController.h"
#import <UserNotifications/UserNotifications.h>

//两次提示的默认间隔
static const CGFloat kDefaultPlaySoundInterval = 3.0;
static NSString *kMessageType = @"MessageType";
static NSString *kConversationChatter = @"ConversationChatter";
static NSString *kGroupName = @"GroupName";

#if DEMO_CALL == 1
@interface MainViewController () <UIAlertViewDelegate, EMCallManagerDelegate>
#else
@interface MainViewController () <UIAlertViewDelegate>
#endif
{
    ConversationListController *_chatListVC;
    ContactListViewController *_contactsVC;
    SettingsViewController *_settingsVC;
//    __weak CallViewController *_callController;
    
    UIBarButtonItem *_addFriendItem;
}

@property (strong, nonatomic) NSDate *lastPlaySoundDate;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //if 使tabBarController中管理的viewControllers都符合 UIRectEdgeNone
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.title = NSLocalizedString(@"title.conversation", @"Conversations");
    
    //获取未读消息数，此时并没有把self注册为SDK的delegate，读取出的未读数是上次退出程序时的
//    [self didUnreadMessagesCountChanged];
    NOTIFY_ADD(setupUntreatedApplyCount, kSetupUntreatedApplyCount);
    NOTIFY_ADD(setupUnreadMessageCount, kSetupUnreadMessageCount);
    NOTIFY_ADD(networkChanged, kConnectionStateChanged);
    
    [self setupSubviews];
    self.selectedIndex = 0;
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [addButton setImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
    [addButton addTarget:_contactsVC action:@selector(addFriendAction) forControlEvents:UIControlEventTouchUpInside];
    _addFriendItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    
    [self setupUnreadMessageCount];
    [self setupUntreatedApplyCount];
    
    TTAlertNoTitle(@"求大侠在github上给简版demo点赞（Star)😘 \n https://github.com/mengmakies/ChatDemo-UI3.00-Simple");
    
    [ChatUIHelper shareHelper].contactViewVC = _contactsVC;
    [ChatUIHelper shareHelper].conversationListVC = _chatListVC;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == 0) {
        self.title = NSLocalizedString(@"title.conversation", @"Conversations");
        self.navigationItem.rightBarButtonItem = nil;
    }else if (item.tag == 1){
        self.title = NSLocalizedString(@"title.addressbook", @"AddressBook");
        self.navigationItem.rightBarButtonItem = _addFriendItem;
    }else if (item.tag == 2){
        self.title = NSLocalizedString(@"title.setting", @"Setting");
        self.navigationItem.rightBarButtonItem = nil;
        [_settingsVC refreshConfig];
    }
}

#pragma mark - private

- (void)setupSubviews
{
    self.tabBar.accessibilityIdentifier = @"tabbar";
    self.tabBar.backgroundImage = [[UIImage imageNamed:@"tabbarBackground"] stretchableImageWithLeftCapWidth:25 topCapHeight:25];
    self.tabBar.selectionIndicatorImage = [[UIImage imageNamed:@"tabbarSelectBg"] stretchableImageWithLeftCapWidth:25 topCapHeight:25];
    
    _chatListVC = [[ConversationListController alloc] initWithNibName:nil bundle:nil];
    [_chatListVC networkChanged:_connectionState];
    _chatListVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"title.conversation", @"Conversations")
                                                           image:[UIImage imageNamed:@"tabbar_chats"]
                                                   selectedImage:[UIImage imageNamed:@"tabbar_chatsHL"]];
    _chatListVC.tabBarItem.tag = 0;
    _chatListVC.tabBarItem.accessibilityIdentifier = @"conversation";
    [self unSelectedTapTabBarItems:_chatListVC.tabBarItem];
    [self selectedTapTabBarItems:_chatListVC.tabBarItem];
    
    _contactsVC = [[ContactListViewController alloc] initWithNibName:nil bundle:nil];
    _contactsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"title.addressbook", @"AddressBook")
                                                           image:[UIImage imageNamed:@"tabbar_contacts"]
                                                   selectedImage:[UIImage imageNamed:@"tabbar_contactsHL"]];
    _contactsVC.tabBarItem.tag = 1;
    _contactsVC.tabBarItem.accessibilityIdentifier = @"contact";
    [self unSelectedTapTabBarItems:_contactsVC.tabBarItem];
    [self selectedTapTabBarItems:_contactsVC.tabBarItem];
    
    _settingsVC = [[SettingsViewController alloc] init];
    _settingsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"title.setting", @"Setting")
                                                           image:[UIImage imageNamed:@"tabbar_setting"]
                                                   selectedImage:[UIImage imageNamed:@"tabbar_settingHL"]];
    _settingsVC.tabBarItem.tag = 2;
    _settingsVC.tabBarItem.accessibilityIdentifier = @"setting";
    _settingsVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self unSelectedTapTabBarItems:_settingsVC.tabBarItem];
    [self selectedTapTabBarItems:_settingsVC.tabBarItem];
    
    self.viewControllers = @[_chatListVC, _contactsVC, _settingsVC];
    [self selectedTapTabBarItems:_chatListVC.tabBarItem];
}

-(void)unSelectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14], NSFontAttributeName,
                                        [UIColor whiteColor],NSForegroundColorAttributeName,
                                        nil] forState:UIControlStateNormal];
}

-(void)selectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14],NSFontAttributeName,
                                        RGBACOLOR(0x00, 0xac, 0xff, 1),NSForegroundColorAttributeName,
                                        nil] forState:UIControlStateSelected];
}

// 统计未读消息数
-(void)setupUnreadMessageCount
{
    NSArray *conversations = [[EMClient sharedClient].chatManager getAllConversations];
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in conversations) {
        unreadCount += conversation.unreadMessagesCount;
    }
    if (_chatListVC) {
        if (unreadCount > 0) {
            _chatListVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%i",(int)unreadCount];
        }else{
            _chatListVC.tabBarItem.badgeValue = nil;
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:unreadCount];
}

- (void)setupUntreatedApplyCount
{
    NSInteger unreadCount = [[[ApplyViewController shareController] dataSource] count];
    if (_contactsVC) {
        if (unreadCount > 0) {
            _contactsVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%i",(int)unreadCount];
        }else{
            _contactsVC.tabBarItem.badgeValue = nil;
        }
    }
}

- (void)networkChanged
{
    _connectionState = [ChatUIHelper shareHelper].connectionState;
    [_chatListVC networkChanged:_connectionState];
}

- (void)playSoundAndVibration{
    NSTimeInterval timeInterval = [[NSDate date]
                                   timeIntervalSinceDate:self.lastPlaySoundDate];
    if (timeInterval < kDefaultPlaySoundInterval) {
        //如果距离上次响铃和震动时间太短, 则跳过响铃
        NSLog(@"skip ringing & vibration %@, %@", [NSDate date], self.lastPlaySoundDate);
        return;
    }
    
    //保存最后一次响铃时间
    self.lastPlaySoundDate = [NSDate date];
    
    // 收到消息时，播放音频
    [[EMCDDeviceManager sharedInstance] playNewMessageSound];
    // 收到消息时，震动
    [[EMCDDeviceManager sharedInstance] playVibration];
}

- (void)showNotificationWithMessage:(EMMessage *)message
{
    EMPushOptions *options = [[EMClient sharedClient] pushOptions];
    NSString *alertBody = nil;
    if (options.displayStyle == EMPushDisplayStyleMessageSummary) {
        EMMessageBody *messageBody = message.body;
        NSString *messageStr = nil;
        switch (messageBody.type) {
            case EMMessageBodyTypeText:
            {
                messageStr = ((EMTextMessageBody *)messageBody).text;
            }
                break;
            case EMMessageBodyTypeImage:
            {
                messageStr = NSLocalizedString(@"message.image", @"Image");
            }
                break;
            case EMMessageBodyTypeLocation:
            {
                messageStr = NSLocalizedString(@"message.location", @"Location");
            }
                break;
            case EMMessageBodyTypeVoice:
            {
                messageStr = NSLocalizedString(@"message.voice", @"Voice");
            }
                break;
            case EMMessageBodyTypeVideo:{
                messageStr = NSLocalizedString(@"message.video", @"Video");
            }
                break;
            default:
                break;
        }

        do {
            NSString *title = [UserCacheManager getNickById:message.from];
            if (message.chatType == EMChatTypeGroupChat) {
                NSDictionary *ext = message.ext;
                if (ext && ext[kGroupMessageAtList]) {
                    id target = ext[kGroupMessageAtList];
                    if ([target isKindOfClass:[NSString class]]) {
                        if ([kGroupMessageAtAll compare:target options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                            alertBody = [NSString stringWithFormat:@"%@%@", title, NSLocalizedString(@"group.atPushTitle", @" @ me in the group")];
                            break;
                        }
                    }
                    else if ([target isKindOfClass:[NSArray class]]) {
                        NSArray *atTargets = (NSArray*)target;
                        if ([atTargets containsObject:[EMClient sharedClient].currentUsername]) {
                            alertBody = [NSString stringWithFormat:@"%@%@", title, NSLocalizedString(@"group.atPushTitle", @" @ me in the group")];
                            break;
                        }
                    }
                }
                NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
                for (EMGroup *group in groupArray) {
                    if ([group.groupId isEqualToString:message.conversationId]) {
                        title = [NSString stringWithFormat:@"%@(%@)", message.from, group.subject];
                        break;
                    }
                }
            }
            else if (message.chatType == EMChatTypeChatRoom)
            {
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                NSString *key = [NSString stringWithFormat:@"OnceJoinedChatrooms_%@", [[EMClient sharedClient] currentUsername]];
                NSMutableDictionary *chatrooms = [NSMutableDictionary dictionaryWithDictionary:[ud objectForKey:key]];
                NSString *chatroomName = [chatrooms objectForKey:message.conversationId];
                if (chatroomName)
                {
                    title = [NSString stringWithFormat:@"%@(%@)", message.from, chatroomName];
                }
            }

            alertBody = [NSString stringWithFormat:@"%@:%@", title, messageStr];
        } while (0);
    }
    else{
        alertBody = NSLocalizedString(@"receiveMessage", @"you have a new message");
    }

    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:self.lastPlaySoundDate];
    BOOL playSound = NO;
    if (!self.lastPlaySoundDate || timeInterval >= kDefaultPlaySoundInterval) {
        self.lastPlaySoundDate = [NSDate date];
        playSound = YES;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:message.chatType] forKey:kMessageType];
    [userInfo setObject:message.conversationId forKey:kConversationChatter];

    //发送本地推送
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.01 repeats:NO];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        if (playSound) {
            content.sound = [UNNotificationSound defaultSound];
        }
        content.body =alertBody;
        content.userInfo = userInfo;
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:message.messageId content:content trigger:trigger];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
    }
    else {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate date]; //触发通知的时间
        notification.alertBody = alertBody;
        notification.alertAction = NSLocalizedString(@"open", @"Open");
        notification.timeZone = [NSTimeZone defaultTimeZone];
        if (playSound) {
            notification.soundName = UILocalNotificationDefaultSoundName;
        }
        notification.userInfo = userInfo;
        
        //发送通知
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
}

#pragma mark - 自动登录回调

- (void)willAutoReconnect{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSNumber *showreconnect = [ud objectForKey:@"identifier_showreconnect_enable"];
    if (showreconnect && [showreconnect boolValue]) {
        [self hideHud];
        [self showHint:NSLocalizedString(@"reconnection.ongoing", @"reconnecting...")];
    }
}

- (void)didAutoReconnectFinishedWithError:(NSError *)error{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSNumber *showreconnect = [ud objectForKey:@"identifier_showreconnect_enable"];
    if (showreconnect && [showreconnect boolValue]) {
        [self hideHud];
        if (error) {
            [self showHint:NSLocalizedString(@"reconnection.fail", @"reconnection failure, later will continue to reconnection")];
        }else{
            [self showHint:NSLocalizedString(@"reconnection.success", @"reconnection successful！")];
        }
    }
}

#pragma mark - public

- (void)jumpToChatList
{
    if ([self.navigationController.topViewController isKindOfClass:[ChatViewController class]]) {
//        ChatViewController *chatController = (ChatViewController *)self.navigationController.topViewController;
//        [chatController hideImagePicker];
    }
    else if(_chatListVC)
    {
        [self.navigationController popToViewController:self animated:NO];
        [self setSelectedViewController:_chatListVC];
    }
}

- (EMConversationType)conversationTypeFromMessageType:(EMChatType)type
{
    EMConversationType conversatinType = EMConversationTypeChat;
    switch (type) {
        case EMChatTypeChat:
            conversatinType = EMConversationTypeChat;
            break;
        case EMChatTypeGroupChat:
            conversatinType = EMConversationTypeGroupChat;
            break;
        case EMChatTypeChatRoom:
            conversatinType = EMConversationTypeChatRoom;
            break;
        default:
            break;
    }
    return conversatinType;
}

- (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo)
    {
        if ([self.navigationController.topViewController isKindOfClass:[ChatViewController class]]) {
//            ChatViewController *chatController = (ChatViewController *)self.navigationController.topViewController;
//            [chatController hideImagePicker];
        }
        
        NSArray *viewControllers = self.navigationController.viewControllers;
        [viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            if (obj != self)
            {
                if (![obj isKindOfClass:[ChatViewController class]])
                {
                    [self.navigationController popViewControllerAnimated:NO];
                }
                else
                {
                    NSString *conversationChatter = userInfo[kConversationChatter];
                    ChatViewController *chatViewController = (ChatViewController *)obj;
                    if (![chatViewController.conversation.conversationId isEqualToString:conversationChatter])
                    {
                        [self.navigationController popViewControllerAnimated:NO];
                        EMChatType messageType = [userInfo[kMessageType] intValue];
#ifdef REDPACKET_AVALABLE
                        chatViewController = [[RedPacketChatViewController alloc]
#else
                        chatViewController = [[ChatViewController alloc]
#endif
                                              initWithConversationChatter:conversationChatter conversationType:[self conversationTypeFromMessageType:messageType]];
                        switch (messageType) {
                            case EMChatTypeChat:
                                {
                                    NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
                                    for (EMGroup *group in groupArray) {
                                        if ([group.groupId isEqualToString:conversationChatter]) {
                                            chatViewController.title = group.subject;
                                            break;
                                        }
                                    }
                                }
                                break;
                            default:
                                chatViewController.title = conversationChatter;
                                break;
                        }
                        [self.navigationController pushViewController:chatViewController animated:NO];
                    }
                    *stop= YES;
                }
            }
            else
            {
                ChatViewController *chatViewController = nil;
                NSString *conversationChatter = userInfo[kConversationChatter];
                EMChatType messageType = [userInfo[kMessageType] intValue];
#ifdef REDPACKET_AVALABLE
                chatViewController = [[RedPacketChatViewController alloc]
#else
                chatViewController = [[ChatViewController alloc]
#endif
                                      initWithConversationChatter:conversationChatter conversationType:[self conversationTypeFromMessageType:messageType]];
                switch (messageType) {
                    case EMChatTypeGroupChat:
                    {
                        NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
                        for (EMGroup *group in groupArray) {
                            if ([group.groupId isEqualToString:conversationChatter]) {
                                chatViewController.title = group.subject;
                                break;
                            }
                        }
                    }
                        break;
                    default:
                        chatViewController.title = conversationChatter;
                        break;
                }
                [self.navigationController pushViewController:chatViewController animated:NO];
            }
        }];
    }
    else if (_chatListVC)
    {
        [self.navigationController popToViewController:self animated:NO];
        [self setSelectedViewController:_chatListVC];
    }
}

- (void)didReceiveUserNotification:(UNNotification *)notification
{
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (userInfo)
    {
        if ([self.navigationController.topViewController isKindOfClass:[ChatViewController class]]) {
            //            ChatViewController *chatController = (ChatViewController *)self.navigationController.topViewController;
            //            [chatController hideImagePicker];
        }

        NSArray *viewControllers = self.navigationController.viewControllers;
        [viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            if (obj != self)
            {
                if (![obj isKindOfClass:[ChatViewController class]])
                {
                    [self.navigationController popViewControllerAnimated:NO];
                }
                else
                {
                    NSString *conversationChatter = userInfo[kConversationChatter];
                    ChatViewController *chatViewController = (ChatViewController *)obj;
                    if (![chatViewController.conversation.conversationId isEqualToString:conversationChatter])
                    {
                        [self.navigationController popViewControllerAnimated:NO];
                        EMChatType messageType = [userInfo[kMessageType] intValue];
#ifdef REDPACKET_AVALABLE
                        chatViewController = [[RedPacketChatViewController alloc]
#else
                        chatViewController = [[ChatViewController alloc]
#endif
                                            initWithConversationChatter:conversationChatter conversationType:[self conversationTypeFromMessageType:messageType]];
                        switch (messageType) {
                            case EMChatTypeChat:
                            {
                                NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
                                for (EMGroup *group in groupArray) {
                                    if ([group.groupId isEqualToString:conversationChatter]) {
                                        chatViewController.title = group.subject;
                                        break;
                                    }
                                }
                            }
                            break;
                            default:
                                chatViewController.title = conversationChatter;
                                break;
                        }
                        [self.navigationController pushViewController:chatViewController animated:NO];
                    }
                    *stop= YES;
                }
            }
            else
            {
                ChatViewController *chatViewController = nil;
                NSString *conversationChatter = userInfo[kConversationChatter];
                EMChatType messageType = [userInfo[kMessageType] intValue];
#ifdef REDPACKET_AVALABLE
                chatViewController = [[RedPacketChatViewController alloc]
#else
                chatViewController = [[ChatViewController alloc]
#endif
                                  initWithConversationChatter:conversationChatter conversationType:[self conversationTypeFromMessageType:messageType]];
                switch (messageType) {
                case EMChatTypeGroupChat:
                    {
                        NSArray *groupArray = [[EMClient sharedClient].groupManager getJoinedGroups];
                        for (EMGroup *group in groupArray) {
                            if ([group.groupId isEqualToString:conversationChatter]) {
                                chatViewController.title = group.subject;
                                break;
                            }
                        }
                    }
                        break;
                    default:
                        chatViewController.title = conversationChatter;
                        break;
                }
                [self.navigationController pushViewController:chatViewController animated:NO];
            }
        }];
    }
    else if (_chatListVC)
    {
        [self.navigationController popToViewController:self animated:NO];
        [self setSelectedViewController:_chatListVC];
    }
}

@end
