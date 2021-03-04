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
    NSString *str = [[NSBundle mainBundle] resourcePath];
    NSString *filePath_0 = [NSString stringWithFormat:@"%@%@",str,@"/Video_0.MP4"];
    NSString *filePath_1 = [NSString stringWithFormat:@"%@%@",str,@"/Video_1.MP4"];
    NSString *filePath_2 = [NSString stringWithFormat:@"%@%@",str,@"/Video_2.MP4"];
    
    NSURL *video_0 = [NSURL fileURLWithPath:filePath_0];
    NSURL *video_1 = [NSURL fileURLWithPath:filePath_1];
    NSURL *video_2 = [NSURL fileURLWithPath:filePath_2];
    
    __weak typeof(self) WS = self;
    [AVFundationCompositionTool compoundVideoWithSubSectionVideoPaths:@[video_0, video_1, video_2]
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
