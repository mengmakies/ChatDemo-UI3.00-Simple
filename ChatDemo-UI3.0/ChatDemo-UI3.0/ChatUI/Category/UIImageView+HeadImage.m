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


#import "UIImageView+HeadImage.h"

@implementation UIImageView (HeadImage)

- (void)imageWithUsername:(NSString *)username placeholderImage:(UIImage*)placeholderImage
{
    if (placeholderImage == nil) {
        placeholderImage = [UIImage imageNamed:@"chatListCellHead"];
    }
    UserCacheInfo *user = [UserCacheManager getById:username];
    if (user) {
        [self sd_setImageWithURL:[NSURL URLWithString:user.AvatarUrl] placeholderImage:placeholderImage];
    } else {
        [self sd_setImageWithURL:nil placeholderImage:placeholderImage];
    }
}

@end

@implementation UILabel (Prase)

- (void)setTextWithUsername:(NSString *)username
{
    UserCacheInfo *user = [UserCacheManager getById:username];
    if (user) {
        [self setText:user.NickName];
        [self setNeedsLayout];
    }
    
}

@end
