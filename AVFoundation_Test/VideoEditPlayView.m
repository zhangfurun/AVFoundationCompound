//
//  VideoEditPlayView.m
//  StoryShip
//
//  Created by ifenghui on 2021/3/3.
//  Copyright © 2021 ifenghui. All rights reserved.
//

#import "VideoEditPlayView.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoEditPlayView ()

/** 播放器 */
@property (nonatomic, strong) AVPlayer *player;
/** 视频资源 */
@property (nonatomic, strong) AVPlayerItem *currentItem;
/** 播放器观察者 */
@property (nonatomic ,strong)  id timeObser;
// 拖动进度条的时候停止刷新数据
@property (nonatomic ,assign) BOOL isSeeking;
// 是否需要缓冲
@property (nonatomic, assign) BOOL isCanPlay;
// 是否需要缓冲
@property (nonatomic, assign) BOOL needBuffer;

@end

@implementation VideoEditPlayView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor blackColor];
        
        self.isCanPlay = NO;
        self.needBuffer = NO;
        self.isSeeking = NO;
        /**
         * 这里view用来做AVPlayer的容器
         * 完成对AVPlayer的二次封装
         * 要求 :
         * 1. 暴露视频输出的API  视频时长 当前播放时间 进度
         * 2. 暴露出易于控制的data入口  播放 暂停 进度拖动 音量 亮度 清晰度调节
         */
        
        
    }
    return self;
}

#pragma mark - 属性和方法
- (NSTimeInterval)totalTime
{
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (CGFloat)volume {
    return self.player.volume;
}

- (void)setVolume:(CGFloat)volume {
    self.player.volume = volume;
}

/**
 准备播放器
 
 @param videoPath 视频地址
 */
- (void)setupPlayerWith:(NSURL *)videoURL
{
    [self creatPlayer:videoURL];
    
    [_player play];
    [self useDelegateWith:AVPlayerStatusLoadingVideo];
}

/**
 avplayer自身有一个rate属性
 rate ==1.0，表示正在播放；rate == 0.0，暂停；rate == -1.0，播放失败
 */

/** 播放 */
- (void)play
{
    if (self.player.rate == 0) {
        [self.player play];
    }
}

/** 暂停 */
- (void)pause
{
    if (self.player.rate == 1.0) {
        [self.player pause];
    }
}

/** 播放|暂停 */
- (void)playOrPause:(void (^)(BOOL isPlay))block;
{
    if (self.player.rate == 0) {
        
        [self.player play];
        
        block(YES);
        
    }else if (self.player.rate == 1.0) {
        
        [self.player pause];
        
        block(NO);
        
    }else {
        NSLog(@"播放器出错");
    }
}

/** 拖动视频进度 */
- (void)seekPlayerTimeTo:(NSTimeInterval)time
{
    [self pause];
    [self startToSeek];
    __weak typeof(self)weakSelf = self;
    
    int32_t timeScale = self.player.currentItem.asset.duration.timescale;
    CMTime cmTime = CMTimeMakeWithSeconds(time, timeScale);
    
    [self.player seekToTime:cmTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf endSeek];
//        [weakSelf play];
    }];
    
}

/** 跳动中不监听 */
- (void)startToSeek
{
    self.isSeeking = YES;
}
- (void)endSeek
{
    self.isSeeking = NO;
}

/**
 切换视频
 
 @param videoURL 视频地址
 */
- (void)replacePalyerItem:(NSURL *)videoURL
{
    self.isCanPlay = NO;
    
    [self pause];
    [self removeNotification];
    [self removeObserverWithPlayItem:self.currentItem];
    
    self.currentItem = [self getPlayerItem:videoURL];
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
    [self addObserverWithPlayItem:self.currentItem];
    [self addNotificatonForPlayer];
    
    [self play];
    
}


/**
  播放状态代理调用
  
  @param status 播放状态
 */
- (void)useDelegateWith:(AVPlayerStatus)status
{
    if (self.isCanPlay == NO) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(promptPlayerStatusOrErrorWith:)]) {
        [self.delegate promptPlayerStatusOrErrorWith:status];
    }
}


#pragma mark - 创建播放器
/**
 获取播放item
 
 @param videoURL 视频网址
 
 @return AVPlayerItem
 */
- (AVPlayerItem *)getPlayerItem:(NSURL *)videoURL
{
    // 转utf8 防止中文报错
//    videoPath = [videoPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//    videoPath = [videoPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // NSURL *url = [NSURL URLWithString:videoPath];
    // 如果播放本地视频要用 NSURL *url = [NSURL fileURLWithPath:videoURL];
    // 所以替换成URL
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:videoURL];
    
    return item;
}


/**
  创建播放器
 
 
 */
- (void)creatPlayer:(NSURL *)videoURL
{
    if (!_player) {
        
        self.currentItem = [self getPlayerItem:videoURL];
        
        _player = [AVPlayer playerWithPlayerItem:self.currentItem];
        
        [self creatPlayerLayer];
        
        [self addPlayerObserver];
        
        [self addObserverWithPlayItem:self.currentItem];
        
        [self addNotificatonForPlayer];
    }
}

/**
 创建播放器 layer 层
 AVPlayerLayer的videoGravity属性设置
 AVLayerVideoGravityResize,       // 非均匀模式。两个维度完全填充至整个视图区域
 AVLayerVideoGravityResizeAspect,  // 等比例填充，直到一个维度到达区域边界
 AVLayerVideoGravityResizeAspectFill, // 等比例填充，直到填充满整个视图区域，其中一个维度的部分区域会被裁剪
 */
- (void)creatPlayerLayer
{
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    layer.frame = self.bounds;
    
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self.layer addSublayer:layer];
}

#pragma mark - 添加 监控
/** 给player 添加 time observer */
- (void)addPlayerObserver
{
    __weak typeof(self)weakSelf = self;
    _timeObser = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        AVPlayerItem *playerItem = weakSelf.player.currentItem;
        
        float current = CMTimeGetSeconds(time);
        
        float total = CMTimeGetSeconds([playerItem duration]);
        
        if (weakSelf.isSeeking) {
            return;
        }
        
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(refreshDataWith:Progress:LoadRange:)]) {
            [weakSelf.delegate refreshDataWith:total Progress:current LoadRange:weakSelf.loadRange];
        }
//        NSLog(@"当前播放进度 %.2f/%.2f.",current,total);
        
    }];
}
/** 移除 time observer */
- (void)removePlayerObserver
{
    [_player removeTimeObserver:_timeObser];
}

/** 给当前播放的item 添加观察者
 
 需要监听的字段和状态
 status :  AVPlayerItemStatusUnknown,AVPlayerItemStatusReadyToPlay,AVPlayerItemStatusFailed
 loadedTimeRanges  :  缓冲进度
 playbackBufferEmpty : seekToTime后，缓冲数据为空，而且有效时间内数据无法补充，播放失败
 playbackLikelyToKeepUp : seekToTime后,可以正常播放，相当于readyToPlay，一般拖动滑竿菊花转，到了这个这个状态菊花隐藏
 
 */
- (void)addObserverWithPlayItem:(AVPlayerItem *)item
{
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}
/** 移除 item 的 observer */
- (void)removeObserverWithPlayItem:(AVPlayerItem *)item
{
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}
/** 数据处理 获取到观察到的数据 并进行处理 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    AVPlayerItem *item = object;
    if ([keyPath isEqualToString:@"status"]) {// 播放状态
        
        [self handleStatusWithPlayerItem:item];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {// 缓冲进度
        
        [self handleLoadedTimeRangesWithPlayerItem:item];
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {// 跳转后没数据
        
        // 转菊花
        if (self.isCanPlay) {
            NSLog(@"跳转后没数据");
            self.needBuffer = YES;
            [self useDelegateWith:AVPlayerStatusCacheData];
        }
        
        
        
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {// 跳转后有数据
        
        
        
        // 隐藏菊花
        if (self.isCanPlay && self.needBuffer) {
            
            NSLog(@"跳转后有数据");
            
            self.needBuffer = NO;
            
            [self useDelegateWith:AVPlayerStatusCacheEnd];
        }
        
    }
}
/**
  处理 AVPlayerItem 播放状态
 AVPlayerItemStatusUnknown           状态未知
 AVPlayerItemStatusReadyToPlay       准备好播放
 AVPlayerItemStatusFailed            播放出错
 */
- (void)handleStatusWithPlayerItem:(AVPlayerItem *)item
{
    AVPlayerItemStatus status = item.status;
    switch (status) {
        case AVPlayerItemStatusReadyToPlay:   // 准备好播放
            
            NSLog(@"AVPlayerItemStatusReadyToPlay");
            self.isCanPlay = YES;
            [self useDelegateWith:AVPlayerStatusReadyToPlay];
            
            break;
        case AVPlayerItemStatusFailed:        // 播放出错
            
            NSLog(@"AVPlayerItemStatusFailed");
            [self useDelegateWith:AVPlayerStatusItemFailed];
            
            break;
        case AVPlayerItemStatusUnknown:       // 状态未知
            
            NSLog(@"AVPlayerItemStatusUnknown");
            
            break;
            
        default:
            break;
    }
    
}
/** 处理缓冲进度 */
- (void)handleLoadedTimeRangesWithPlayerItem:(AVPlayerItem *)item
{
    NSArray *loadArray = item.loadedTimeRanges;
    
    CMTimeRange range = [[loadArray firstObject] CMTimeRangeValue];
    
    float start = CMTimeGetSeconds(range.start);
    
    float duration = CMTimeGetSeconds(range.duration);
    
    NSTimeInterval totalTime = start + duration;// 缓存总长度
    
    _loadRange = totalTime;
//    NSLog(@"缓冲进度 -- %.2f",totalTime);
    
}


/**
 添加关键通知
 
 AVPlayerItemDidPlayToEndTimeNotification     视频播放结束通知
 AVPlayerItemTimeJumpedNotification           视频进行跳转通知
 AVPlayerItemPlaybackStalledNotification      视频异常中断通知
 UIApplicationDidEnterBackgroundNotification  进入后台
 UIApplicationDidBecomeActiveNotification     返回前台
 
 */
- (void)addNotificatonForPlayer
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(videoPlayEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
//    [center addObserver:self selector:@selector(videoPlayToJump:) name:AVPlayerItemTimeJumpedNotification object:nil];//没意义
    [center addObserver:self selector:@selector(videoPlayError:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayEnterBack:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(videoPlayBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}
/** 移除 通知 */
- (void)removeNotification
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
//    [center removeObserver:self name:AVPlayerItemTimeJumpedNotification object:nil];
    [center removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [center removeObserver:self];
}

- (void)setIsOpenAVFundationNotification:(BOOL)isOpenAVFundationNotification {
    _isOpenAVFundationNotification = isOpenAVFundationNotification;
    if (_isOpenAVFundationNotification) {
        [self addNotificatonForPlayer];
    } else {
        [self removeNotification];
    }
}

/** 视频播放结束 */
- (void)videoPlayEnd:(NSNotification *)notic
{
    NSLog(@"视频播放结束");
    [self useDelegateWith:AVPlayerStatusPlayEnd];
    [self.player seekToTime:kCMTimeZero];
    if (self.isReplay) {
        [self play];
    }
}
///** 视频进行跳转 */ 没有意义的方法 会被莫名的多次调动，不清楚机制
//- (void)videoPlayToJump:(NSNotification *)notic
//{
//    NSLog(@"视频进行跳转");
//}
/** 视频异常中断 */
- (void)videoPlayError:(NSNotification *)notic
{
    NSLog(@"视频异常中断");
    [self useDelegateWith:AVPlayerStatusPlayStop];
}
/** 进入后台 */
- (void)videoPlayEnterBack:(NSNotification *)notic
{
    NSLog(@"进入后台");
    [self useDelegateWith:AVPlayerStatusEnterBack];
}
/** 返回前台 */
- (void)videoPlayBecomeActive:(NSNotification *)notic
{
    NSLog(@"返回前台");
    [self useDelegateWith:AVPlayerStatusBecomeActive];
}

#pragma mark - 销毁 release
- (void)dealloc
{
    NSLog(@"--- %@ --- 销毁了",[self class]);
    
    [self removeNotification];
    [self removePlayerObserver];
    [self removeObserverWithPlayItem:self.player.currentItem];
    
}

@end
