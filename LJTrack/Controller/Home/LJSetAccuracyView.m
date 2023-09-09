//
//  LJSetAccuracyView.m
//  LJTrack
//
//  Created by 李杰 on 2023/9/9.
//  Copyright © 2023 LiJie. All rights reserved.
//

#import "LJSetAccuracyView.h"
#import <MAMapKit/MAMapKit.h>
#import "AppDelegate.h"

@interface LJSetAccuracyView()

@property (weak, nonatomic) IBOutlet UIView *infoBackView;

@end

@implementation LJSetAccuracyView

- (void)awakeFromNib{
    
    [super awakeFromNib];
    
    self.infoBackView.layer.cornerRadius = 4;
    self.infoBackView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.infoBackView.layer.shadowOffset = CGSizeMake(0, 2);
    self.infoBackView.layer.shadowOpacity = 0.3;
    
    @weakify(self);
    [self addTapGestureHandler:^(UITapGestureRecognizer *tap, UIView *itself) {
        @strongify(self);
        [self hidePop];
    }];
    [self.infoBackView addTapGestureHandler:^(UITapGestureRecognizer *tap, UIView *itself) {
    }];
    
    self.horizontalSlider.value = 40;
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"horizontalAccuracy"]) {
        self.horizontalSlider.value = [[[NSUserDefaults standardUserDefaults]objectForKey:@"horizontalAccuracy"] floatValue];
    }
    
    self.verticalSlider.value = 30;
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"verticalAccuracy"]) {
        self.verticalSlider.value = [[[NSUserDefaults standardUserDefaults]objectForKey:@"verticalAccuracy"] floatValue];
    }
    
    self.minSpeedSlider.value = 0.36;
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"minSpeed"]) {
        self.minSpeedSlider.value = [[[NSUserDefaults standardUserDefaults]objectForKey:@"minSpeed"] floatValue];
    }
    
    self.maxSpeedSlider.value = 120;
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"maxSpeed"]) {
        self.maxSpeedSlider.value = [[[NSUserDefaults standardUserDefaults]objectForKey:@"maxSpeed"] floatValue];
    }
    [self refreshUI];
}
- (IBAction)horizontalValueChange:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.value) forKey:@"horizontalAccuracy"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [self refreshUI];
}
- (IBAction)verticalValueChange:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.value) forKey:@"verticalAccuracy"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [self refreshUI];
}
- (IBAction)minSpeedValueChange:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.value) forKey:@"minSpeed"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [self refreshUI];
}
- (IBAction)maxSpeedValueChange:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults]setObject:@(sender.value) forKey:@"maxSpeed"];
    [[NSUserDefaults standardUserDefaults]synchronize];
    [self refreshUI];
}




-(void)refreshUI{
    self.horizontalTitleLabel.text = [NSString stringWithFormat:@"水平精度%.0f", self.horizontalSlider.value];
    self.verticalTitleLabel.text = [NSString stringWithFormat:@"垂直精度%.0f", self.verticalSlider.value];
    self.minSpeedTitleLabel.text = [NSString stringWithFormat:@"最小速度%.2f公里/小时", self.minSpeedSlider.value];
    if (self.maxSpeedSlider.value > 150) {
        self.maxSpeedTitleLabel.text = @"最大速度 不做限制";
    }else{
        self.maxSpeedTitleLabel.text = [NSString stringWithFormat:@"最大速度%.2f公里/小时", self.maxSpeedSlider.value];
    }
    
}
-(void)setLocation:(CLLocation *)location{
    _location = location;
    
    if (location) {
        self.currentLocationInfoLabel.text = [NSString stringWithFormat:@"当前位置信息:\n高度:%.1f米, 速度:%.2f公里/小时,\n水平精度:%.0f, 垂直精度:%.0f", location.altitude, location.speed*3.6, location.horizontalAccuracy, location.verticalAccuracy];
    }
}


-(void)hidePop{
    self.hidden = YES;
    [self removeFromSuperview];
}

-(void)showPop{
    self.frame = CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT);
    [[UIApplication sharedApplication].delegate.window addSubview:self];
    self.hidden = NO;
}
@end
