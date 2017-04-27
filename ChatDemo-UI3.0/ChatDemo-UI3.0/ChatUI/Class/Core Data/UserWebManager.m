//
//  UserWebManager.m
//  mt
//
//  Created by martin on 16/11/2.
//  Copyright © 2016 martin. All rights reserved.
//

#import "UserWebManager.h"
#import "AVOSCloud/AVObject+Subclass.h"// 实现子类化

@implementation UserWebInfo
@dynamic openId;
@dynamic nickName;
@dynamic avatarUrl;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return NSStringFromClass(UserWebInfo.class);
}

@end

@implementation UserWebManager

+(void)initialize{
}


/**
 配置Web数据存储服务

 @param launchOptions 程序入口参数
 @param appId 数据存储服务的AppID
 @param appKey 数据存储服务的AppKey
 */
+ (void)config:(NSDictionary *)launchOptions
         appId:(NSString*)appId
        appKey:(NSString*)appKey
{
    // 如果使用美国站点，请加上下面这行代码：
    // [AVOSCloud setServiceRegion:AVServiceRegionUS];
    
    // 在https://leancloud.cn里获取
    [AVOSCloud setApplicationId:appId clientKey:appKey];
    
    // 跟踪统计应用的打开情况
    [AVAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
}


/**
 创建用户
 @param openId 环信ID
 @param nickName 用户昵称
 @param avatarUrl 用户头像（绝对路径)
 */
+(void)createUser:(NSString*)openId
         nickName:(NSString*)nickName
        avatarUrl:(NSString*)avatarUrl{
    [self getUserInfo:openId completed:^(UserWebInfo *user) {
        if(user) return;
        
        UserWebInfo *info = [UserWebInfo object];
        info.openId = openId;
        info.nickName = nickName;
        info.avatarUrl = avatarUrl;
        [info saveEventually];// 如果用户目前尚未接入网络，saveEventually会缓存设备中的数据，并在网络连接恢复后上传
    }];
}

/**
 *  删除查询的所有缓存结果
 */
+(void)clearCache{
    [AVQuery clearAllCachedResults];
}

/*
 *保存用户信息（如果已存在，则更新）
 *userId: 用户环信id
 *imgUrl：用户头像链接（完整路径）
 *nickName: 用户昵称
 */
+(void)saveInfo:(NSString*)userId
         imgUrl:(NSString*)imgUrl
       nickName:(NSString*)nickName{
    
    [self getUserInfo:userId completed:^(UserWebInfo *user) {
        if(!user){
            user = [UserWebInfo object];
            user.openId = userId;
        }
        user.nickName = nickName;
        user.avatarUrl = imgUrl;
        [user saveEventually];// 如果用户目前尚未接入网络，saveEventually会缓存设备中的数据，并在网络连接恢复后上传
    }];
    
#if DEBUG
    [self queryAll];
#endif
    
}

// 构造查询器
+(AVQuery*) getQuery{
    AVQuery *query = [UserWebInfo query];
    
    // 查询行为先尝试从网络加载，若加载失败，则从缓存加载结果
//    query.cachePolicy = kAVCachePolicyNetworkElseCache;

    //设置缓存有效期：一天
    query.maxCacheAge = 24*3600;
    
    return query;
}

+(void)queryAll{
    AVQuery *query = [self getQuery];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects && objects.count > 0) {
            // 成功找到结果，先找磁盘再访问网络
            UserWebInfo *user = (UserWebInfo*)[objects objectAtIndex:0];
        } else {
            // 无法访问网络，本次查询结果未做缓存
        }
    }];
}

// 更新当前用户的昵称
+(void)updateMyNick:(NSString*)nickName
            completed:(void(^)(BOOL isSucc))completed{
    
    [self getUserInfo:kCurrEaseUserId completed:^(UserWebInfo *user) {
        
        if (!user) {
            // 无法访问网络，本次查询结果未做缓存
            completed(NO);
            return ;
        }
        
        // 成功找到结果，先找磁盘再访问网络
        user.nickName = nickName;
        [user saveEventually];// 如果用户目前尚未接入网络，saveEventually会缓存设备中的数据，并在网络连接恢复后上传
        
        // 本地重新缓存用户数据
        [UserCacheManager updateMyNick:nickName];
        
        completed(YES);
    }];
}

// 更新当前用户的头像
+(void)updateMyAvatar:(UIImage*)pickImage
            completed:(void(^)(UIImage *imageData))completed{
    
    pickImage = [self imageWithImageSimple:pickImage scaledToSize:CGSizeMake(250., 250.)];
    
    NSData *imageData = UIImagePNGRepresentation(pickImage);
    AVFile *file = [AVFile fileWithName:@"avatar.png" data:imageData];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(error){
            completed(nil);
            return;
        }
        
        //返回一个用户头像的 Url 地址
        NSString *avatarUrl = file.url;
        
        AVQuery *query = [self getQuery];
        [query whereKey:@"openId" equalTo:kCurrEaseUserId];
        [query getFirstObjectInBackgroundWithBlock:^(AVObject *object, NSError *error) {
            if (!error && object) {// 成功找到结果，先找磁盘再访问网络
                UserWebInfo *user = (UserWebInfo*)object;
                user.avatarUrl = avatarUrl;
                [user saveEventually];// 如果用户目前尚未接入网络，saveEventually会缓存设备中的数据，并在网络连接恢复后上传
            } else {
                // 无法访问网络，本次查询结果未做缓存
            }
            
            // 本地重新缓存用户数据
            [UserCacheManager updateMyAvatar:avatarUrl];
            
            completed(pickImage);
        }];
    }];
    
    
}

+ (UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

/*
 *根据环信ID获取用户信息
 *userId 用户的环信id
 */
+(UserWebInfo*)getUserInfo:(NSString *)userid{
    
    UserWebInfo *user = nil;
    @try {
        AVQuery *query = [self getQuery];
        [query whereKey:@"openId" equalTo:userid];
        user = (UserWebInfo*)[query getFirstObject];
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
    return user;
}

/*
 *根据环信ID获取用户信息
 *userId 用户的环信id
 */
+(void)getUserInfo:(NSString *)userid
          completed:(void(^)(UserWebInfo *user))completed{
    
    if(!userid){
        completed(nil);
        return;
    }
    
    AVQuery *query = [self getQuery];
    [query whereKey:@"openId" equalTo:userid];
    [query getFirstObjectInBackgroundWithBlock:^(AVObject * _Nullable object, NSError * _Nullable error) {
        if (!error) {
            completed((UserWebInfo*)object);
            return;
        }
        
        completed(nil);
    }];
}

/*
 * 根据环信ID获取昵称
 * userId:环信用户id
 */
+(NSString*)getNickName:(NSString*)userId{
    UserWebInfo *user = [self getUserInfo:userId];
    if(user == nil || [user  isEqual: @""]) return userId;// 没有昵称就返回用户ID
    
    return user.nickName;
}

/*
 * 获取当前环信用户信息
 */
+(UserWebInfo*)myInfo{
    return [self getUserInfo:kCurrEaseUserId];
}

/*
 * 获取当前环信用户的昵称
 */
+(NSString*)myNickName{
    return [self getNickName:kCurrEaseUserId];
}

@end
