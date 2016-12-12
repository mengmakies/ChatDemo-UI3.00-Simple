//
//  UserCacheManager.m
//  mt
//
//  Created by martin on 16/10/24.
//  Copyright © 2016 martin. All rights reserved.
//

#import "UserCacheManager.h"
#import "FMDB.h"
#import "UserWebManager.h"

#define DBNAME @"user_cache_data.db"
static FMDatabaseQueue *_queue;

@implementation UserCacheInfo

@end

@implementation UserCacheManager

+(void)initialize{
    NSString *fileName = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject] stringByAppendingPathComponent:DBNAME];
    
    _queue = [FMDatabaseQueue databaseQueueWithPath:fileName];
    [_queue inDatabase:^(FMDatabase *db) {
        // userid 环信ID，username 用户昵称，userimage 用户头像完整路径
        [db executeUpdate:@"create table if not exists userinfo (userid text, username text, userimage text, expired_time text)"];
    }];
}

/**
 *  执行一个更新语句
 *
 *  @param sql 更新语句的sql
 *
 *  @return 更新语句的执行结果
 */
+(BOOL)executeUpdate:(NSString *)sql{
    
    __block BOOL updateRes = NO;
    
    [_queue inDatabase:^(FMDatabase *db) {
        
        updateRes = [db executeUpdate:sql];
    }];
    
    return updateRes;
}


/**
 *  执行一个查询语句
 *
 *  @param sql              查询语句sql
 *  @param queryResBlock    查询语句的执行结果
 */
+(void)executeQuery:(NSString *)sql queryResBlock:(void(^)(FMResultSet *set))queryResBlock{
    
    [_queue inDatabase:^(FMDatabase *db) {
        
        FMResultSet *set = [db executeQuery:sql];
        
        if(queryResBlock != nil) queryResBlock(set);
        
    }];
}

/**
 *  用户是否存在
 *
 *  @param userId 用户环信ID
 *
 *  @return 是否存在
 */
+(BOOL)isExistUser:(NSString *)userId{
    
    NSString *alias=@"count";
    
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) AS %@ FROM userinfo where userid = '%@'", alias, userId];
    
    __block NSUInteger count=0;
    
    [self executeQuery:sql queryResBlock:^(FMResultSet *set) {
        
        while ([set next]) {
            
            count = [[set stringForColumn:alias] integerValue];
        }
    }];
    
    return count > 0;
}


/**
 判断缓存中的用户是否过期

 @param userId 用户环信id

 @return 是否过期
 */
+(BOOL)isExpired:(NSString*)userId{
    BOOL isExpired = NO;
    
    UserCacheInfo *user = [self getByIdFromCache:userId];
    if(!user) return YES;
    
    NSDate *currDate = [NSDate date];
    long long currMill = (long long)([currDate timeIntervalSince1970]);
    if (currMill > user.ExpiredDate) {
        isExpired = YES;
    }
    
    return  isExpired;
}

/**
 *  清空表（但不清除表结构）
 *
 *  @return 操作结果
 */
+(BOOL)clearTableData{
    
    BOOL res = [self executeUpdate:@"DELETE FROM userinfo"];
    [self executeUpdate:@"DELETE FROM sqlite_sequence WHERE name='userinfo';"];
    return res;
}

/*
 *保存用户信息（如果已存在，则更新）
 *userId: 用户环信ID
 *imgUrl：用户头像链接（完整路径）
 *nickName: 用户昵称
 */
+(void)saveInfo:(NSString*)userId
         imgUrl:(NSString*)imgUrl
       nickName:(NSString*)nickName{
    NSString *sql = @"";
    
    // 过期时间
    NSDate *currDate = [NSDate date];
    static int timeOut = 24 * 60 * 60;// 缓存一天，可以根据项目需要更改缓存时间
    long long currMillis = ((long long)([currDate timeIntervalSince1970])) + timeOut;
    NSString *strTime = [NSString stringWithFormat:@"%lld", currMillis];
    
    BOOL isExistUser = [self isExistUser:userId];
    if (isExistUser) {
        sql = [NSString stringWithFormat:@"update userinfo set username='%@', userimage='%@', expired_time='%@' where userid='%@'", nickName,imgUrl, strTime,userId];
    }else{
        sql = [NSString stringWithFormat:@"INSERT INTO userinfo (userid, username, userimage, expired_time) VALUES ('%@', '%@', '%@', '%@')", userId,nickName,imgUrl,strTime];
    }
    
    [self executeUpdate:sql];
    
#if DEBUG
    [self queryAll];
#endif
}

+(void)saveInfo:(NSDictionary *)userinfo{
    NSString *userid = [userinfo objectForKey:kChatUserId];
    NSString *username = [userinfo objectForKey:kChatUserNick];
    NSString *userimage = [userinfo objectForKey:kChatUserPic];
    
    [self saveInfo:userid imgUrl:userimage nickName:username];
}

+(void)queryAll{
    // 列出所有用户信息
    NSString *sql = @"SELECT userid, username, userimage FROM userinfo";
    [self executeQuery:sql queryResBlock:^(FMResultSet *rs) {
        int i=0;
        while ([rs next]) {
            NSLog(@"%d：-------",i);
            NSLog(@"id：%@",[rs stringForColumn:@"userid"]);
            NSLog(@"name：%@",[rs stringForColumn:@"username"]);
            NSLog(@"image：%@",[rs stringForColumn:@"userimage"]);
            NSLog(@"%d：---end--",i);
            i++;
        }
        [rs close];
    }];
}

// 更新当前用户的昵称
+(void)updateCurrNick:(NSString*)nickName{
    UserCacheInfo *user = [self currUser];
    if (!user)  return;
    
    [self saveInfo:user.Id imgUrl:user.AvatarUrl nickName:nickName];
}

// 更新当前用户的昵称
+(void)updateCurrAvatar:(NSString*)avatarUrl{
    UserCacheInfo *user = [self currUser];
    if (!user)  return;
    
    [self saveInfo:user.Id imgUrl:avatarUrl nickName:user.NickName];
}

/*
 *根据环信ID获取用户信息
 *userId 用户的环信ID
 */
+(UserCacheInfo*)getById:(NSString *)userid{
    
    __block UserCacheInfo *userInfo = nil;
    
    // 如果本地缓存不存在或者过期，则从存储服务器获取
    BOOL isExistUser = [self isExistUser:userid];
    if (!isExistUser || [self isExpired:userid]) {
        [UserWebManager getByIdAsync:userid completed:^(UserWebInfo *user) {
            if(!user) return;
            
            // 缓存到本地
            [self saveInfo:userid imgUrl:user.avatarUrl nickName:user.nickName];
            
            // 通知刷新会话列表
            NOTIFY_POST(kRefreshChatList);// 如果app没有会话列表，可以删掉这行代码
        }];
    }
    
    // 从本地缓存中获取用户数据
    userInfo = [self getByIdFromCache:userid];
    
    return userInfo;
}

/*
 *根据环信ID获取用户信息
 *userId 用户的环信ID
 */
+(UserCacheInfo*)getByIdFromCache:(NSString *)userid{
    
    __block UserCacheInfo *userInfo = nil;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT userid, username, userimage,expired_time FROM userinfo where userid = '%@'",userid];
    [self executeQuery:sql queryResBlock:^(FMResultSet *rs) {
        if ([rs next]) {
            
            userInfo = [[UserCacheInfo alloc] init];
            
            userInfo.Id = [rs stringForColumn:@"userid"];
            userInfo.NickName = [rs stringForColumn:@"username"];
            userInfo.AvatarUrl = [rs stringForColumn:@"userimage"];
            userInfo.ExpiredDate = [[rs stringForColumn:@"expired_time"] longLongValue];
        }
        [rs close];
    }];
    
    return userInfo;
}

/*
 * 根据环信ID获取昵称
 * userId:环信用户id
 */
+(NSString*)getNickById:(NSString*)userId{
    UserCacheInfo *user = [UserCacheManager getById:userId];
    if(user == nil || [user  isEqual: @""]) return userId;// 没有昵称就返回用户环信ID
    
    return user.NickName;
}

/*
 * 获取当前环信用户信息
 */
+(UserCacheInfo*)currUser{
    return [UserCacheManager getById:kCurrEaseUserId];
}

/*
 * 获取当前环信用户的昵称
 */
+(NSString*)currNickName{
    return [UserCacheManager getNickById:kCurrEaseUserId];
}

@end
