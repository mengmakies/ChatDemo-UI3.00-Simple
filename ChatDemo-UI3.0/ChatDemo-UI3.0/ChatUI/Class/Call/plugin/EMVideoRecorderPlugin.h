/*!
 *  \~chinese
 *  @header EMVideoRecorderPlugin.h
 *  @abstract 录制视频插件，与视频通话配合使用
 *  @author Hyphenate
 *  @version 3.00
 *
 *  \~english
 *  @header EMVideoRecorderPlugin.h
 *  @abstract Setting options of Apple Push Notification
 *  @author Hyphenate
 *  @version 3.00
 */
#import <Foundation/Foundation.h>

@class EMError;
@interface EMVideoRecorderPlugin : NSObject

/*!
 *  \~chinese
 *  初始化全局设置, 必须在视频通话开始之前调用
 *
 *  \~english
 *  Init global config，it must be called before the video call begins.
 */
+ (void)initGlobalConfig;

/*!
 *  \~chinese
 *  获取插件实例
 *
 *  \~english
 *  Get plugin singleton instance
 */
+ (instancetype)sharedInstance;

/*!
 *  \~chinese
 *  获取视频快照，只支持JPEG格式
 *
 *  @param aPath  图片存储路径
 *
 *  \~english
 *  Get a snapshot of current video screen as jpeg picture and save to the local file system.
 *
 *  @param aPath  Saved path of picture
 */
- (void)screenCaptureToFilePath:(NSString *)aPath
                          error:(EMError**)pError;

/*!
 *  \~chinese
 *  开始录制视频
 *
 *  @param aPath            文件保存路径
 *  @param aError           错误
 *
 *  \~english
 *  Start recording video
 *
 *  @param aPath            File saved path
 *  @param aError           Error
 
 *
 */
- (void)startVideoRecordingToFilePath:(NSString*)aPath
                                error:(EMError**)aError;

/*!
 *  \~chinese
 *  停止录制视频
 *
 *  @param aError           错误
 *
 *  \~english
 *  Stop recording video
 *
 *  @param aError           Error
 *
 */
- (NSString *)stopVideoRecording:(EMError**)aError;

@end
