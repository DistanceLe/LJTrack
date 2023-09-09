//
//  LJSetAccuracyView.h
//  LJTrack
//
//  Created by 李杰 on 2023/9/9.
//  Copyright © 2023 LiJie. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CLLocation;


NS_ASSUME_NONNULL_BEGIN

@interface LJSetAccuracyView : UIView

@property (nonatomic, strong) CLLocation *location;

@property (weak, nonatomic) IBOutlet UILabel *currentLocationInfoLabel;

@property (weak, nonatomic) IBOutlet UILabel *horizontalTitleLabel;
@property (weak, nonatomic) IBOutlet UISlider *horizontalSlider;

@property (weak, nonatomic) IBOutlet UILabel *verticalTitleLabel;
@property (weak, nonatomic) IBOutlet UISlider *verticalSlider;

@property (weak, nonatomic) IBOutlet UILabel *minSpeedTitleLabel;
@property (weak, nonatomic) IBOutlet UISlider *minSpeedSlider;

@property (weak, nonatomic) IBOutlet UILabel *maxSpeedTitleLabel;
@property (weak, nonatomic) IBOutlet UISlider *maxSpeedSlider;


-(void)showPop;
-(void)hidePop;

@end

NS_ASSUME_NONNULL_END
