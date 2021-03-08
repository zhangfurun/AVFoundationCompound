//
//  ViewController.m
//  AVFoundation_Test
//
//  Created by ifenghui on 2021/3/4.
//

#import "ViewController.h"

#import "VideoEditPlayView.h"

#import "AVFundationCompositionTool.h"

#define kCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
// 发布视频的文件路径
static NSString * const CompositionVideoMP4Name = @"CompositionVideoMP4Name.mp4";
#define COMPOUND_VIDEO_MP4_FILE_PATH [kCachePath stringByAppendingPathComponent:CompositionVideoMP4Name]

@interface ViewController ()<VideoEditPlayViewDelegate>
@property (nonatomic, strong) VideoEditPlayView *player;

@property (weak, nonatomic) IBOutlet UIButton *btn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setPlayerDefault];
    
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect rect = self.view.bounds;
    CGFloat startY = 150;
    rect.origin.y = startY;
    rect.size.height = rect.size.height - startY;
    self.player.frame = rect;
}


- (VideoEditPlayView *)player {
    if (!_player) {
        _player = [[VideoEditPlayView alloc] init];
        _player.isReplay = YES;
    }
    return _player;
}

- (void)setPlayerDefault {
    self.player = [[VideoEditPlayView alloc] init];
    
    self.player.isReplay = YES;
    
    self.player.delegate = self;
    
    [self.view insertSubview:self.player atIndex:0];
}

- (void)startPlayCompoundVideo {
    [self.player setupPlayerWith:[NSURL fileURLWithPath:COMPOUND_VIDEO_MP4_FILE_PATH]];
}

- (IBAction)onCompoundBtnTap:(UIButton *)sender {
//    [self viodesCompound];
    [self videosAndAudioCompound];
}

- (void)viodesCompound {
    NSString *str = [[NSBundle mainBundle] resourcePath];
    
    NSMutableArray *videos = [NSMutableArray array];
    for (int i = 0; i < 5; i++) {
        NSString *filePath = [NSString stringWithFormat:@"%@/Video_%d.mp4",str, i];
        NSURL *video = [NSURL fileURLWithPath:filePath];
        [videos addObject:video];
    }
    
    __weak typeof(self) WS = self;
    [AVFundationCompositionTool compoundVideoWithSubSectionVideoPaths:videos
                                                    compoundVideoPath:COMPOUND_VIDEO_MP4_FILE_PATH
                                                       completedBlock:^(BOOL success, NSString * _Nonnull errorMsg) {
        if (success) {
            NSLog(@"成功");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [WS startPlayCompoundVideo];
            });
        } else {
            NSLog(@"失败");
        }
    }];
}

- (void)videosAndAudioCompound {
    NSMutableArray *videos = [NSMutableArray array];

    NSString *str = [[NSBundle mainBundle] resourcePath];
    for (int i = 0; i < 5; i++) {
        NSString *filePath = [NSString stringWithFormat:@"%@/Video_%d.mp4",str, i];
        NSURL *video = [NSURL fileURLWithPath:filePath];
        [videos addObject:video];
    }
    
    NSURL *audio_0 = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@",str,@"/bgm.mp3"]];
    
    __weak typeof(self) WS = self;
    [AVFundationCompositionTool compoundVideoWithSubSectionVideoPaths:videos
                                                            audioPath:audio_0
                                                    compoundVideoPath:COMPOUND_VIDEO_MP4_FILE_PATH
                                                       completedBlock:^(BOOL success, NSString * _Nonnull errorMsg) {
        if (success) {
            NSLog(@"成功");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [WS startPlayCompoundVideo];
            });
        } else {
            NSLog(@"失败");
        }
    }];
}

- (void)promptPlayerStatusOrErrorWith:(AVPlayerStatus)status {
    if (status == AVPlayerStatusPlayEnd) {
//        [self.player play];
    }
}
@end
