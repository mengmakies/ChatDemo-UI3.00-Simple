//
//  UserCacheManager.m
//  mt
//
//  Created by martin on 16/10/24.
//  Copyright © 2016 martin. All rights reserved.
//

#import <Foundation/Foundation.h>

// 环信聊天用的昵称和头像（发送聊天消息时，要附带这3个属性）
#define kChatUserId @"ChatUserId"// 环信ID
#define kChatUserNick @"ChatUserNick"// 昵称
#define kChatUserPic @"ChatUserPic"// 头像url

#define kCurrEaseUserId [[EMClient sharedClient] currentUsername]// 当前用户的环信ID

@interface UserCacheInfo : NSObject
@property(nonatomic,copy)NSString* userId;
@property(nonatomic,copy)NSString* nickName;
@property(nonatomic,copy)NSString* avatarUrl;
@property(nonatomic,assign)long long expiredDate;
@end


@interface UserCacheManager : NSObject

/**
 保存（新增或更新）用户信息
 @param userId 用户环信ID
 @param avatarUrl 头像Url
 @param nickName 昵称
 */
+(void)save:(NSString *)userId
  avatarUrl:(NSString*)avatarUrl
   nickName:(NSString*)nickName;

/**
 保存（新增或更新）用户信息
 @param userinfo 昵称和头像
 */
+(void)save:(NSDictionary *)userinfo;


/**
 保存（新增或更新）用户信息

 @param jsonStr 昵称和头像的json字符串
 */
+(void)saveWithJson:(NSString *)jsonStr;

/*!
 获取用户信息
 @param userId                  用户环信ID
 @param completed               获取用户信息完成之后需要执行的Block
 @param userInfo(in completed) 该用户ID对应的用户信息。
 */
+ (void)getUserInfo:(NSString *)userId
          completed:(void (^)(UserCacheInfo *userInfo))completed;

/**
 更新当前用户的昵称
 @param nickName 昵称
 */
+(void)updateMyNick:(NSString*)nickName;


/**
 更新当前用户的头像
 @param avatarUrl 头像Url（完成路径）
 */
+(void)updateMyAvatar:(NSString*)avatarUrl;

/**
 根据环信ID获取用户信息
 @param userid 用户的环信ID
 @return 用户信息
 */
+(UserCacheInfo*)getUserInfo:(NSString *)userid;

/**
 根据环信ID获取昵称
 @param userId 用户的环信ID
 @return 昵称
 */
+(NSString*)getNickName:(NSString*)userId;


/**
 获取当前环信用户信息
 @return 头像昵称
 */
+(UserCacheInfo*)myInfo;


/**
 获取当前环信用户的昵称
 @return 昵称
 */
+(NSString*)myNickName;


/**
 清除数据
 @return 是否成功
 */
+(BOOL)clearData;

/**
获取登录用户的消息扩展属性
 
 @param msgExt 消息原有的扩展属性
 @return 重新组合的扩展属性
 */
+(NSMutableDictionary*)getMyMsgExt;


/**
重新设置登录用户的消息扩展属性
 
 @param msgExt 消息原有的扩展属性
 @return 重新组合的扩展属性
 */
+(NSMutableDictionary*)getMyMsgExt:(NSDictionary *)msgExt;

// 设置头像控件
+(void)setUserAvatar:(NSString*)userId
           imageView:(UIImageView*)imageView;

// 设置昵称控件
+(void)setUserNick:(NSString*)userId
         nickLabel:(UILabel*)nameLabel;

// 设置头像昵称
+(void)setUserView:(NSString*)userId
         nickLabel:(UILabel*)nameLabel
         imageView:(UIImageView*)imageView;

@end

