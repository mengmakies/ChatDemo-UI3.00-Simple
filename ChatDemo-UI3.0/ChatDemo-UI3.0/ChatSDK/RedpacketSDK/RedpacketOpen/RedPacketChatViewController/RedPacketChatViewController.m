//
//  ChatWithRedPacketViewController.m
//  ChatDemo-UI3.0
//
//  Created by Mr.Yang on 16/2/23.
//  Copyright © 2016年 Mr.Yang. All rights reserved.
//

#import "RedPacketChatViewController.h"
#import "EaseRedBagCell.h"
#import "RedpacketTakenMessageTipCell.h"
#import "RedpacketViewControl.h"
#import "RedpacketMessageModel.h"
#import "RedPacketUserConfig.h"
#import "RedpacketOpenConst.h"
#import "YZHRedpacketBridge.h"
#import "ChatUIHelper.h"

#import "UIImageView+WebCache.h"

/** 红包聊天窗口 */
@interface RedPacketChatViewController () < EaseMessageCellDelegate,
                                            EaseMessageViewControllerDataSource,
                                            RedpacketViewControlDelegate>
/** 发红包的控制器 */
@property (nonatomic, strong)   RedpacketViewControl *viewControl;

@end

@implementation RedPacketChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /** RedPacketUserConfig 持有当前聊天窗口 */
    [RedPacketUserConfig sharedConfig].chatVC = self;
    /** 红包功能的控制器， 产生用户单击红包后的各种动作 */
    _viewControl = [[RedpacketViewControl alloc] init];
    /** 获取群组用户代理 */
    _viewControl.delegate = self;
    /** 需要当前的聊天窗口 */
    _viewControl.conversationController = self;
    /** 需要当前聊天窗口的会话ID */
    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
    userInfo.userId = self.conversation.conversationId;
    _viewControl.converstationInfo = userInfo;
    __weak typeof(self) weakSelf = self;
    /** 用户抢红包和用户发送红包的回调 */
    [_viewControl setRedpacketGrabBlock:^(RedpacketMessageModel *messageModel) {
        /** 发送通知到发送红包者处 */
        if (messageModel.redpacketType != RedpacketTypeAmount) {
            [weakSelf sendRedpacketHasBeenTaked:messageModel];
        }
    } andRedpacketBlock:^(RedpacketMessageModel *model) {
        /** 发送红包 */
        [weakSelf sendRedPacketMessage:model];
    }];
    
    /** 设置用户头像大小 */
    [[EaseRedBagCell appearance] setAvatarSize:40.f];
    /** 设置头像圆角 */
    [[EaseRedBagCell appearance] setAvatarCornerRadius:20.f];
    
    if ([self.chatToolbar isKindOfClass:[EaseChatToolbar class]]) {
        /** 红包按钮 */
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket"] highlightedImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket_high"] title:@"红包"];
        /** 转账按钮 */
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedPacketResource.bundle/redpacket_transfer_high"] highlightedImage:[UIImage imageNamed:@"RedPacketResource.bundle/redpacket_transfer_high"] title:@"转账"];
    }
}

#pragma mark - Delegate RedpacketViewControlDelegate
- (void)getGroupMemberListCompletionHandle:(void (^)(NSArray<RedpacketUserInfo *> *))completionHandle
{
    EMGroup *group = [[[EMClient sharedClient] groupManager] fetchGroupInfo:self.conversation.conversationId includeMembersList:YES error:nil];
    NSMutableArray *mArray = [[NSMutableArray alloc]init];
    
    for (NSString *username in group.occupants) {
        /** 创建一个用户模型 并赋值 */
        RedpacketUserInfo *userInfo = [self profileEntityWith:username];
        [mArray addObject:userInfo];
    }
    completionHandle(mArray);
}

/** 要在此处根据userID获得用户昵称,和头像地址 */
- (RedpacketUserInfo *)profileEntityWith:(NSString *)userId
{
    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];

    UserCacheInfo * user = [UserCacheManager getUserInfo:userId];
    userInfo.userNickname = user.nickName;
    userInfo.userAvatar = user.avatarUrl;
    userInfo.userId = userId;
    return userInfo;
}

/** 长时间按在某条Cell上的动作 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController canLongPressRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    if ([object conformsToProtocol:NSProtocolFromString(@"IMessageModel")]) {
        id <IMessageModel> messageModel = object;
        NSDictionary *ext = messageModel.message.ext;
        /** 如果是红包，则只显示删除按钮 */
        if ([RedpacketMessageModel isRedpacket:ext]) {
            EaseMessageCell *cell = (EaseMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell becomeFirstResponder];
            self.menuIndexPath = indexPath;
            [self showMenuViewController:cell.bubbleView andIndexPath:indexPath messageType:EMMessageBodyTypeCmd];
            return NO;
        }else if ([RedpacketMessageModel isRedpacketTakenMessage:ext]) {
            return NO;
        }
    }
    return [super messageViewController:viewController canLongPressRowAtIndexPath:indexPath];
}

#pragma mrak - 自定义红包的Cell
- (UITableViewCell *)messageViewController:(UITableView *)tableView
                       cellForMessageModel:(id<IMessageModel>)messageModel
{
    NSDictionary *ext = messageModel.message.ext;
    if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
        if ([RedpacketMessageModel isRedpacket:ext] || [RedpacketMessageModel isRedpacketTransferMessage:ext]) {
            EaseRedBagCell *cell = [tableView dequeueReusableCellWithIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]];
            if (!cell) {
                cell = [[EaseRedBagCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel] model:messageModel];
                cell.delegate = self;
            }
            cell.model = messageModel;
            return cell;
        }
        RedpacketTakenMessageTipCell *cell =  [[RedpacketTakenMessageTipCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [cell configWithRedpacketMessageModel:[RedpacketMessageModel redpacketMessageModelWithDic:ext]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    return nil;
}

- (CGFloat)messageViewController:(EaseMessageViewController *)viewController
           heightForMessageModel:(id<IMessageModel>)messageModel
                   withCellWidth:(CGFloat)cellWidth
{
    NSDictionary *ext = messageModel.message.ext;
    if ([RedpacketMessageModel isRedpacket:ext] || [RedpacketMessageModel isRedpacketTransferMessage:ext])    {
        return [EaseRedBagCell cellHeightWithModel:messageModel];
    }else if ([RedpacketMessageModel isRedpacketTakenMessage:ext]) {
        return [RedpacketTakenMessageTipCell heightForRedpacketMessageTipCell];
    }
    return 0;
}

#pragma mark - DataSource
/** 未读消息回执 */
- (BOOL)messageViewController:(EaseMessageViewController *)viewController
shouldSendHasReadAckForMessage:(EMMessage *)message
                         read:(BOOL)read
{
    NSDictionary *ext = message.ext;
    if ([RedpacketMessageModel isRedpacketRelatedMessage:ext]) {
        return YES;
    }
    return [super shouldSendHasReadAckForMessage:message read:read];
}

#pragma mark - 发送红包消息
- (void)messageViewController:(EaseMessageViewController *)viewController didSelectMoreView:(EaseChatBarMoreView *)moreView AtIndex:(NSInteger)index
{
    if (self.conversation.type == EMConversationTypeChat) {
        /** 单聊发送界面 */
        if (index == 5) {
            [self.viewControl presentRedPacketViewControllerWithType:RPSendRedPacketViewControllerRand memberCount:0];
        }else {
            /** 转账页面 */
            RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
            userInfo = [self profileEntityWith:self.conversation.conversationId];
            [self.viewControl presentTransferViewControllerWithReceiver:userInfo];
        }
    }else{
        NSArray *groupArray = [EMGroup groupWithId:self.conversation.conversationId].occupants;
        /** 群聊红包发送界面 */
        [self.viewControl presentRedPacketViewControllerWithType:RPSendRedPacketViewControllerMember memberCount:groupArray.count];
    }
}

#pragma mark - 发送红包消息
- (void)sendRedPacketMessage:(RedpacketMessageModel *)model
{
    NSDictionary *dic = [model redpacketMessageModelToDic];
    NSString *message;
    if ([RedpacketMessageModel isRedpacketTransferMessage:dic]) {
        message = [NSString stringWithFormat:@"[转账]转账%@元",model.redpacket.redpacketMoney];
    }else {
        message = [NSString stringWithFormat:@"[%@]%@", model.redpacket.redpacketOrgName, model.redpacket.redpacketGreeting];
    }
    [self sendTextMessage:message withExt:dic];
}

#pragma mark -  发送红包被抢的消息
- (void)sendRedpacketHasBeenTaked:(RedpacketMessageModel *)messageModel
{
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *senderId = messageModel.redpacketSender.userId;
    NSString *conversationId = self.conversation.conversationId;
    NSMutableDictionary *dic = [messageModel.redpacketMessageModelToDic mutableCopy];
    /** 忽略推送 */
    [dic setValue:@(YES) forKey:@"em_ignore_notification"];
    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", messageModel.redpacketSender.userNickname];
    if (self.conversation.type == EMConversationTypeChat) {
        [self sendTextMessage:text withExt:dic];
    }else{
        if ([senderId isEqualToString:currentUser]) {
            text = @"你领取了自己的红包";
        }else {
            /** 如果不是自己发的红包，则发送抢红包消息给对方 */
            [[EMClient sharedClient].chatManager sendMessage:[self createCmdMessageWithModel:messageModel] progress:nil completion:nil];
        }
        EMTextMessageBody *textMessageBody = [[EMTextMessageBody alloc] initWithText:text];
        EMMessage *textMessage = [[EMMessage alloc] initWithConversationID:conversationId from:currentUser to:conversationId body:textMessageBody ext:dic];
        textMessage.chatType = (EMChatType)self.conversation.type;
        textMessage.isRead = YES;
        /** 刷新当前聊天界面 */
        [self addMessageToDataSource:textMessage progress:nil];
        /** 存入当前会话并存入数据库 */
        [self.conversation insertMessage:textMessage error:nil];
    }
}

- (EMMessage *)createCmdMessageWithModel:(RedpacketMessageModel *)model
{
    NSMutableDictionary *dict = [model.redpacketMessageModelToDic mutableCopy];
    
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *toUser = model.redpacketSender.userId;
    EMCmdMessageBody *cmdChat = [[EMCmdMessageBody alloc] initWithAction:RedpacketKeyRedapcketCmd];
    EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId from:currentUser to:toUser body:cmdChat ext:dict];
    message.chatType = EMChatTypeChat;
    
    return message;
}

#pragma mark - EaseMessageCellDelegate 单击了Cell 事件
- (void)messageCellSelected:(id<IMessageModel>)model
{
    NSDictionary *dict = model.message.ext;
    if ([RedpacketMessageModel isRedpacket:dict]) {
        [self.viewControl redpacketCellTouchedWithMessageModel:[self toRedpacketMessageModel:model]];
    }else if([RedpacketMessageModel isRedpacketTransferMessage:dict]) {
        [self.viewControl presentTransferDetailViewController:[RedpacketMessageModel redpacketMessageModelWithDic:dict]];
    }else {
        [super messageCellSelected:model];
    }
}

- (RedpacketMessageModel *)toRedpacketMessageModel:(id <IMessageModel>)model
{
    RedpacketMessageModel *messageModel = [RedpacketMessageModel redpacketMessageModelWithDic:model.message.ext];
    if (self.conversation.type == EMConversationTypeGroupChat) {
        messageModel.redpacketSender = [self profileEntityWith:model.message.from];
        messageModel.toRedpacketReceiver = [self profileEntityWith:messageModel.toRedpacketReceiver.userId];
    }else{
        messageModel.redpacketSender = [self profileEntityWith:model.message.from];
    }
    return messageModel;
}

@end
