//
//  LJPlayStringAudio.m
//  LJTrack
//
//  Created by lijie on 2022/4/21.
//  Copyright © 2022 LiJie. All rights reserved.
//

#import "LJPlayStringAudio.h"
#import <AVFoundation/AVFoundation.h> //导入播放声音的框架
#import <MediaPlayer/MediaPlayer.h>


@interface LJPlayStringAudio ()<AVSpeechSynthesizerDelegate>

//@property (nonatomic, strong)AVSpeechSynthesizer *avSpeaker;
@property (nonatomic, strong)NSMutableArray *speechStringsArr;//存放要播放的内容
@property (nonatomic, strong)AVSpeechSynthesizer *synthesizer;
//@property (nonatomic, strong)NSArray *voices;

//@property (nonatomic, strong)AVPlayerItem *playerItem;//AVPlayer 切换播放源
//@property (nonatomic, strong)AVPlayer *player;

@property(nonatomic, assign)CGFloat oldVolume;


@end


@implementation LJPlayStringAudio


+ (instancetype)share
{
    static dispatch_once_t onceToken;
    static LJPlayStringAudio *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[LJPlayStringAudio alloc] init];
    });
    return instance;
}


-(instancetype)init {
    
    if(self = [super init]){
        
        //再选择需要使用的语言zh-CN  en-US
//        _voices = @[[AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"], [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"], [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"]];
        _speechStringsArr = [NSMutableArray array];
    }
    return  self;
}


#pragma mark - GET
-(AVSpeechSynthesizer *)synthesizer {
    
    if (!_synthesizer) {
        
        //初始化语音合成器
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
    }
    return _synthesizer;
}

#pragma mark - SET
-(void)setPlayContentStr:(NSString *)playContentStr {
    
    //将播放消息插入数组
    DLog(@"%@",playContentStr);
    
    if(playContentStr.length > 0 && playContentStr != nil){
        
        _playContentStr = playContentStr;
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:_playContentStr];
        
        
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithAttributedString:attrStr];
        // 设置语音
        AVSpeechSynthesisVoice *voices = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
        utterance.voice = voices;
        // 设置速率
        utterance.rate = 0.4;
        // 设置语调
        utterance.pitchMultiplier = 1;
        // 设置音量 没作用
//        utterance.volume = 1;
        // 播报前停顿
        utterance.preUtteranceDelay = 0;
        // 播报后停顿
        utterance.postUtteranceDelay = 0;
        
        if(self.speechStringsArr.count > 0) {//存在没有播放完的数据
            
            //插入数组
            [self.speechStringsArr addObject:utterance];
            
        } else {//不存在要播放的数据
            [self.speechStringsArr addObject:utterance];
            [self beginConversationWith:utterance];
        }
    }
}

/**  准备开始播放 */
-(void)readyPlay{
    [[AVAudioSession sharedInstance]setActive:YES error:nil];//激活语音
    
    if (self.needZoomInAudio) {
        //增大音量，并且记录旧的音量
        self.oldVolume = [self getSystemVolume];
        MPMusicPlayerController* musicController = [MPMusicPlayerController applicationMusicPlayer];
        musicController.volume = (self.oldVolume>0?self.oldVolume*1.4:0.4);
    }
    
}
/**  播放完成 */
-(void)playOver{
    if (self.needZoomInAudio) {
        //恢复之前的音量
        MPMusicPlayerController* musicController = [MPMusicPlayerController applicationMusicPlayer];
        musicController.volume = self.oldVolume;
    }
    
    //关闭语音， 让后台的其他音乐继续播放
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

/**  开始播放 */
- (void)beginConversationWith:(AVSpeechUtterance *)utterance {
    
    [self readyPlay];
    [self.synthesizer speakUtterance:utterance];
}
//暂停播放
-(void)pausePlay{
    //停止语音
    [self playOver];
    [self.synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}
//继续播放
-(void)continuePlay {
    [self readyPlay];
    [self.synthesizer continueSpeaking];
}
//停止播放， 完全清空
-(void)stopPlay {
    //停止语音
    [self playOver];
    [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    if (self.speechStringsArr.count) {
        [self.speechStringsArr removeAllObjects];
    }
}

-(CGFloat)getSystemVolume{
    
    UISlider * volumeViewSlider = nil;
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(10, 50, 200, 4)];
    for (UIView* newView in volumeView.subviews) {
        if ([newView.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)newView;
            break;
        }
    }
    //在app刚刚初始化的时候使用MPVolumeView获取音量大小可能为0
    return volumeViewSlider.value > 0 ? volumeViewSlider.value : [[AVAudioSession sharedInstance]outputVolume];
}



#pragma mark - ================ 代理 ==================
//将要说某段话
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    
    DLog(@"将要说某段话");
}

//已经开始
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    
    DLog(@"已经开始");
}
//已经说完
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    
    DLog(@"已经说完");
    
    //已经说完情况下移除播放内容
    for (AVSpeechUtterance *item in self.speechStringsArr) {
        
        if ([item isEqual:utterance]) {
            
            [self.speechStringsArr removeObject:item];
            break;
        }
    }
    
    //判断数据是否还存在未播放的数据, 如果存在继续播放
    if (self.speechStringsArr.count > 0) {
        
        //播放第一个数据
        [self  beginConversationWith:self.speechStringsArr.firstObject];
    }else{
        //停止语音
        [self playOver];
    }
}



//已经暂停
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    DLog(@"已经暂停");
}
//已经继续说话
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    DLog(@"已经继续说话");
}
//已经取消说话
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    DLog(@"已经取消说话");
    [self playOver];
    if (self.speechStringsArr.count) {
        [self.speechStringsArr removeAllObjects];
    }
}




@end
