//
//  LJPlayStringAudio.h
//  LJTrack
//
//  Created by lijie on 2022/4/21.
//  Copyright © 2022 LiJie. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LJPlayStringAudio : NSObject


//提供单利方法,以便调用
+ (instancetype)share;

@property (nonatomic, copy)NSString *playContentStr;//设置播放内容，并开始播放


-(void)stopPlay;//停止， 完全清空
-(void)pausePlay;//暂停， 可以继续播放
-(void)continuePlay;//继续播放


@end

NS_ASSUME_NONNULL_END
