/*!
 *  \~chinese
 *  @header EMCallOptions.h
 *  @abstract EMCallManager配置类
 *  @author Hyphenate
 *  @version 3.00
 *
 *  \~english
 *  @header EMCallOptions.h
 *  @abstract EMCallManager setting options
 *  @author Hyphenate
 *  @version 3.00
 */

#import <Foundation/Foundation.h>

#import "EMCallEnum.h"

@interface EMCallOptions : NSObject

/*!
 *  \~chinese
 *  被叫方不在线时，是否推送来电通知
 *  如果设置为NO，不推送通知，返回EMErrorCallRemoteOffline
 *  默认NO
 *
 *  \~english
 *  When remote is not online, whether to send offline push
 *  default NO
 */
@property (nonatomic, assign) BOOL isSendPushIfOffline;

/*!
 *  \~chinese
 *  当isSendPushIfOffline=YES时起作用,离线推送显示的内容
 *  默认 “You have incoming call...”
 *
 *  \~english
 *  Only effective when isSendPushIfOffline is YES.
 *  default “You have incoming call...”
 */
@property (nonatomic, strong) NSString *offlineMessageText;

/*!
 *  \~chinese
 *  视频分辨率
 *  默认自适应
 *
 *  \~english
 *  Video resolution
 *  default adaptive
 */
@property (nonatomic, assign) EMCallVideoResolution videoResolution;

/*!
 *  \~chinese
 *  视频码率
 *  范围 50 < videoKbps < 5000, 默认0, 0为自适应
 *  建议设置为0
 *
 *  \~english
 *  Video kbps
 *  range 50 < videoKbps < 5000, default 0 , 0 means adaptive
 *  advice 0
 */
@property (nonatomic, assign) long videoKbps;

@end
