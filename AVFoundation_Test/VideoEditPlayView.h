//
//  VideoEditPlayView.h
//  StoryShip
//
//  Created by ifenghui on 2021/3/3.
//  Copyright © 2021 ifenghui. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
// 这个为简单的视频循环播放, 不支持自定义

// 默认为 全屏幕显示, 循环播放


typedef NS_ENUM(NSInteger, ZFR_AVPlayerStatus) {
    ZFR_AVPlayerStatusReadyToPlay = 0, // 准备好播放
    ZFR_AVPlayerStatusLoadingVideo,    // 加载视频
    ZFR_AVPlayerStatusPlayEnd,         // 播放结束
    ZFR_AVPlayerStatusCacheData,       // 缓冲视频
    ZFR_AVPlayerStatusCacheEnd,        // 缓冲结束
    ZFR_AVPlayerStatusPlayStop,        // 播放中断 （多是没网）
    ZFR_AVPlayerStatusItemFailed,      // 视频资源问题
    ZFR_AVPlayerStatusEnterBack,       // 进入后台
    ZFR_AVPlayerStatusBecomeActive,    // 从后台返回
};

@protocol VideoEditPlayViewDelegate <NSObject>

@optional
// 数据刷新
- (void)refreshDataWith:(NSTimeInterval)totalTime Progress:(NSTimeInterval)currentTime LoadRange:(NSTimeInterval)loadTime;
// 状态/错误 提示
- (void)promptPlayerStatusOrErrorWith:(ZFR_AVPlayerStatus)status;

@end

@interface VideoEditPlayView : UIView

@property (nonatomic, weak) id<VideoEditPlayViewDelegate>delegate;
@property (nonatomic, assign) CGFloat volume;
// 视频总长度
@property (nonatomic, assign) NSTimeInterval totalTime;
// 视频总长度
//@property (nonatomic, assign) NSTimeInterval currentTime;
// 缓存数据
@property (nonatomic, assign) NSTimeInterval loadRange;
@property (nonatomic, assign) BOOL isReplay;
@property (nonatomic, assign) BOOL isOpenAVFundationNotification;

/**
 准备播放器
 
 @param videoPath 视频地址
 */
//- (void)setupPlayerWith:(NSString *)videoPath;
- (void)setupPlayerWith:(NSURL *)videoURL;

/** 播放 */
- (void)play;

/** 暂停 */
- (void)pause;

/** 播放|暂停 */
- (void)playOrPause:(void (^)(BOOL isPlay))block;

/** 拖动视频进度 */
- (void)seekPlayerTimeTo:(NSTimeInterval)time;

/** 跳动中不监听 */
- (void)startToSeek;

/**
 切换视频
 
 @param videoPath 视频地址
 */
//- (void)replacePalyerItem:(NSString *)videoPath;
- (void)replacePalyerItem:(NSURL *)videoURL;
@end

NS_ASSUME_NONNULL_END
