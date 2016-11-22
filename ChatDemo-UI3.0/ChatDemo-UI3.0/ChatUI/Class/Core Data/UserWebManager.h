//
//  UserWebManager.m
//  mt
//
//  Created by martin on 16/10/24.
//  Copyright © 2016 martin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kCurrEaseUserId [[EMClient sharedClient] currentUsername]// 当前用户的环信ID

@interface UserWebInfo : AVObject <AVSubclassing>
@property(nonatomic,copy)NSString* openId;
@property(nonatomic,copy)NSString* nickName;
@property(nonatomic,copy)NSString* avatarUrl;
@end


@interface UserWebManager : NSObject

/**
 配置Web数据存储服务
 
 @param launchOptions 程序入口参数
 @param appId 数据存储服务的AppID
 @param appKey 数据存储服务的AppKey
 */
+ (void)config:(NSDictionary *)launchOptions
         appId:(NSString*)appId
        appKey:(NSString*)appKey;

/**
 创建用户
 @param openId 环信ID
 @param nickName 用户昵称
 @param avatarUrl 用户头像（绝对路径)
 */
+(void)createUser:(NSString*)openId
         nickName:(NSString*)nickName
        avatarUrl:(NSString*)avatarUrl;

/*
 *保存用户信息（如果已存在，则更新）
 *userId: 用户环信id
 *imgUrl：用户头像链接（完整路径）
 *nickName: 用户昵称
 */
+(void)saveInfo:(NSString *)userId
         imgUrl:(NSString*)imgUrl
       nickName:(NSString*)nickName;

// 更新当前用户的昵称
+(void)updateCurrNick:(NSString*)nickName
            completed:(void(^)(BOOL isSucc))completed;

// 更新当前用户的头像
+(void)updateCurrAvatar:(UIImage*)pickImage
              completed:(void(^)(UIImage *imageData))completed;

/*
 *根据环信ID获取用户信息
 *userId 用户的环信id
 */
+(UserWebInfo*)getById:(NSString *)userid;

/*
 *根据环信ID获取用户信息
 *userId 用户的环信id
 */
+(void)getByIdAsync:(NSString *)userid
          completed:(void(^)(UserWebInfo *user))completed;

/*
 * 根据环信ID获取昵称
 * userId:环信用户id
 */
+(NSString*)getNickById:(NSString*)userId;

/*
 * 获取当前环信用户信息
 */
+(UserWebInfo*)currUser;

/*
 * 获取当前环信用户的昵称
 */
+(NSString*)currNickName;

/**
 *  删除查询的所有缓存结果
 */
+(void)clearCache;

@end

