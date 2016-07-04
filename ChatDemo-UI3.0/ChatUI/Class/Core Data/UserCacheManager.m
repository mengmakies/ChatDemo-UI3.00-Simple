//
//  UserCacheManager.m
//  ypp
//
//  Created by Stephen Chin on 16/06/05.
//  Copyright © 2016 martin. All rights reserved.
//

#import "UserCacheManager.h"
#import "FMDB.h"
#import "MKNetworkKit.h"

#define DBNAME @"user_cache_data.db"

@implementation UserCacheInfo

@end

@implementation UserCacheManager

+(void)createTable:(FMDatabase *)db
{
    if ([db open]) {
        if (![db tableExists :@"userinfo"]) {
            if ([db executeUpdate:@"create table userinfo (userid text, username text, userimage text)"]) {
                NSLog(@"create table success");
            }else{
                NSLog(@"fail to create table");
            }
        }else {
             NSLog(@"table is already exist");
        }
    }else{
        NSLog(@"fail to open");
    }
}

+ (void)clearTableData:(FMDatabase *)db
{
    if ([db executeUpdate:@"DELETE FROM userinfo"]) {
        NSLog(@"clear successed");
    }else{
        NSLog(@"fail to clear");
    }
}

+(FMDatabase*)getDB{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath   = [docsPath stringByAppendingPathComponent:DBNAME];
    FMDatabase *db     = [FMDatabase databaseWithPath:dbPath];
    [self createTable:db];
    return db;
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
    NSMutableDictionary *extDic = [NSMutableDictionary dictionary];
    [extDic setValue:userId forKey:kChatUserId];
    [extDic setValue:imgUrl forKey:kChatUserPic];
    [extDic setValue:nickName forKey:kChatUserNick];
    [UserCacheManager saveDict:extDic];
}

+(void)saveDict:(NSDictionary *)userinfo{
    FMDatabase *db     = [self getDB];
    
    NSString *userid = [userinfo objectForKey:kChatUserId];
    if ([db executeUpdate:@"DELETE FROM userinfo where userid = ?", userid]) {
        DLog(@"删除成功");
    }else{
        DLog(@"删除失败");
    }
    NSString *username = [userinfo objectForKey:kChatUserNick];
    NSString *userimage = [userinfo objectForKey:kChatUserPic];
    if ([db executeUpdate:@"INSERT INTO userinfo (userid, username, userimage) VALUES (?, ?, ?)", userid,username,userimage]) {
        DLog(@"插入成功");
    }else{
        DLog(@"插入失败");
    }
    
    FMResultSet *rs = [db executeQuery:@"SELECT userid, username, userimage FROM userinfo where userid = ?",userid];
    if ([rs next]) {
        NSString *userid = [rs stringForColumn:@"userid"];
        NSString *username = [rs stringForColumn:@"username"];
        NSString *userimage = [rs stringForColumn:@"userimage"];
        DLog(@"查询一个 %@ %@ %@",userid,username,userimage);
    }
    
    rs = [db executeQuery:@"SELECT userid, username, userimage FROM userinfo"];
    while ([rs next]) {
        NSString *userid = [rs stringForColumn:@"userid"];
        NSString *username = [rs stringForColumn:@"username"];
        NSString *userimage = [rs stringForColumn:@"userimage"];
        DLog(@"查询所有 %@ %@ %@",userid,username,userimage);
    }
    
    [rs close];
    [db close];
}

/*
 *根据环信ID获取用户信息
 *userId 用户的环信ID
 */
+(UserCacheInfo*)getById:(NSString *)userid{
    FMDatabase *db     = [self getDB];
    if ([db open]) {
        FMResultSet *rs = [db executeQuery:@"SELECT userid, username, userimage FROM userinfo where userid = ?",userid];
        if ([rs next]) {
            
            UserCacheInfo *userInfo = [[UserCacheInfo alloc] init];
            
            userInfo.Id = [rs stringForColumn:@"userid"];
            userInfo.NickName = [rs stringForColumn:@"username"];
            userInfo.AvatarUrl = [rs stringForColumn:@"userimage"];
            DLog(@"查询一个 %@",userInfo);
            return userInfo;
        }else{
            return nil;
        }
    }else{
        return nil;
    }
}

/*
 * 根据环信ID获取昵称
 * userId:环信用户id
 */
+(NSString*)getNickById:(NSString*)userId{
    UserCacheInfo *user = [UserCacheManager getById:userId];
    if(user == nil || [user  isEqual: @""]) return @"";
    
    return user.NickName;
}

/*
 * 获取当前环信用户信息
 */
+(UserCacheInfo*)getCurrUser{
    return [UserCacheManager getById:kCURRENT_USERNAME];
}


@end
