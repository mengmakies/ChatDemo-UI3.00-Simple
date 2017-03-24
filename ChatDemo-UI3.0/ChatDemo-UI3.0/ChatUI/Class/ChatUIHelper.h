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

#import <Foundation/Foundation.h>

#import "ConversationListController.h"
#import "ContactListViewController.h"
#import "ChatViewController.h"

#define kHaveUnreadAtMessage    @"kHaveAtMessage"
#define kAtYouMessage           1
#define kAtAllMessage           2

@interface ChatUIHelper : NSObject <EMClientDelegate,EMChatManagerDelegate,EMContactManagerDelegate,EMGroupManagerDelegate,EMChatroomManagerDelegate>

@property (nonatomic, weak) ContactListViewController *contactViewVC;

@property (nonatomic, weak) ConversationListController *conversationListVC;

@property (nonatomic, weak) UIViewController *mainVC;

@property (nonatomic, weak) ChatViewController *chatVC;

@property (nonatomic, assign)EMConnectionState connectionState;

@property (strong, nonatomic) NSDate *lastPlaySoundDate;

+ (instancetype)shareHelper;

- (void)asyncPushOptions;

- (void)asyncGroupFromServer;

- (void)asyncConversationFromDB;

@end
