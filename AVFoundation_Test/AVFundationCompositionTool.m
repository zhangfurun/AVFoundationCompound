//
//  AVFundationCompositionTool.m
//  AVFoundation_Test
//
//  Created by ifenghui on 2021/3/4.
//

#import "AVFundationCompositionTool.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVFundationCompositionTool
+ (void)compoundVideoWithSubSectionVideoPaths:(NSArray<NSURL *> *)videoPaths
                            compoundVideoPath:(NSString *)compoundVideoPath
                               completedBlock:(CompFinalCompletedBlock)completedBlock {
    [self compoundVideoWithSubSectionVideoPaths:videoPaths
                                      audioPath:nil
                              compoundVideoPath:compoundVideoPath
                                 completedBlock:completedBlock];
}

+ (void)compoundVideoWithSubSectionVideoPaths:(NSArray<NSURL *> *)videoPaths
                                    audioPath:(NSURL * __nullable)audioPath
                            compoundVideoPath:(NSString *)compoundVideoPath
                               completedBlock:(CompFinalCompletedBlock)completedBlock {
    if (!videoPaths || videoPaths.count == 0) {
        NSLog(@"No such SubsectionNames");
        completedBlock(NO, @"视频为空");
        return;
    }
    // 合成工具
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    // 创建获取素材参数, 这个可以直接为nil, 下方的参数含义是获取素材参数的时间为非精准, 默认为精准
    NSDictionary *optDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                        forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    // 合成工具的视频轨道
    __block AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 合成工具的音频轨道
    __block AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    

    __block CMTime allTime = kCMTimeZero;
    // 遍历视频资源
    [videoPaths enumerateObjectsUsingBlock:^(NSURL *videoPath, NSUInteger idx, BOOL * _Nonnull stop) {
        // 素材
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoPath options:optDict];
        // 获取素材中的轨道_视频
        NSArray<AVAssetTrack *> *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (videoTracks <= 0) {
            *stop = YES;
            completedBlock(NO, @"合成失败");
            return;
        }
        
        
        // 获取当前视频的时间长度
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
        // 素材的视频轨道
        AVAssetTrack *videoCompositionTrack = videoTracks.firstObject;
        // 设置合成工具的preferredTransform
        [compositionVideoTrack setPreferredTransform:videoCompositionTrack.preferredTransform];
        // 将素材的视频轨道添加到合成工具的视频轨道
        [compositionVideoTrack insertTimeRange:timeRange
                                       ofTrack:videoTracks.firstObject
                                        atTime:allTime
                                         error:nil];
        
        NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count > 0) {
            // 将素材的音频轨道添加到合成工具的音频轨道
            [compositionAudioTrack insertTimeRange:timeRange
                                           ofTrack:audioTracks.firstObject
                                            atTime:allTime
                                             error:nil];
        }
        
        allTime = CMTimeAdd(allTime, asset.duration);
    }];
    
    if (audioPath) {
        // 背景音乐 合成轨道
        AVMutableCompositionTrack *compositionBGMAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];

        // 背景音乐
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:audioPath options:optDict];
        CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, allTime);
        NSArray *bgmTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
        [compositionBGMAudioTrack insertTimeRange:timeRange
                                          ofTrack:bgmTracks.firstObject
                                           atTime:kCMTimeZero
                                            error:nil];
    }
    
    // 存在旧数据, 删除旧数据
    if ([[NSFileManager defaultManager] fileExistsAtPath:compoundVideoPath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:compoundVideoPath error:&error];
    }
    
    NSURL *outUrl = [NSURL fileURLWithPath:compoundVideoPath];
    // 输出工具
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    // 输出类型
    exporter.outputFileType = AVFileTypeMPEG4;
    // 输出路径
    exporter.outputURL = outUrl;
    // 优化
    exporter.shouldOptimizeForNetworkUse = YES;
//    exporter.audioMix = audioMix;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        BOOL isSuccess = NO;
        NSString *msg = @"合并完成";
        switch (exporter.status) {
            case AVAssetExportSessionStatusFailed:
                NSLog(@"MediaManager -> combinationVidesError: %@", exporter.error.localizedDescription);
                NSLog(@"%@", exporter.error);
                msg = @"合并失败";
                break;
            case AVAssetExportSessionStatusUnknown:
            case AVAssetExportSessionStatusCancelled:
                break;
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                isSuccess = YES;
                break;
        }
        if (completedBlock) {
            completedBlock(isSuccess, msg);
        }
    }];
}
@end
