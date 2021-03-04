//
//  AVFundationCompositionTool.h
//  AVFoundation_Test
//
//  Created by ifenghui on 2021/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompFinalCompletedBlock)(BOOL success, NSString *errorMsg);

@interface AVFundationCompositionTool : NSObject
+ (void)compoundVideoWithSubSectionVideoPaths:(NSArray<NSURL *> *)videoPaths
                            compoundVideoPath:(NSString *)compoundVideoPath
                               completedBlock:(CompFinalCompletedBlock)completedBlock;
@end

NS_ASSUME_NONNULL_END
