//
//  LJMainViewController.m
//  LJTrack
//
//  Created by LiJie on 16/6/14.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import "LJMainViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <MAMapKit/MATraceManager.h>
#import "MAAnnotationView+LJ.h"

#import "LJPullDownView.h"
#import "WSLineChartView.h"

#import "TimeTools.h"
#import "LJImageTools.h"
#import "LJOptionPlistFile.h"

#import "LJPlayStringAudio.h"
#import "LJSetAccuracyView.h"

typedef NS_ENUM(int, LJPlayAudioType) {
    /**  不播报 */
    LJPlayAudioType_None = 0,
    
    /**  0.01 公里 10米 播报一次 */
    LJPlayAudioType_001,
    /**  0.1 公里 100米 播报一次 */
    LJPlayAudioType_01,
    /**  1 公里 播报一次 */
    LJPlayAudioType_1,
};





@interface LJMainViewController ()<MAMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *trackInfoLabel;

@property(nonatomic, strong)MAMapView* mainMapView;
@property(nonatomic, strong)MAPolygon* backMaskPolygon;

@property(nonatomic, weak)LJPullDownView* altitudePullView;
@property(nonatomic, strong)WSLineChartView* altitudeLineView;

@property(nonatomic, strong)LJSetAccuracyView* setAccuracyView;


@property(nonatomic, strong)MAAnnotationView* annotationView;
@property(nonatomic, strong)MAUserLocation* currentLocationInfo;
@property(nonatomic, assign)CLLocationCoordinate2D currentLocation;
@property(nonatomic, strong)NSMutableArray* locationsArray;
@property(nonatomic, strong)NSMutableArray* colorArray;
@property(nonatomic, strong)NSMutableArray* trackColorArray;
@property(nonatomic, strong)NSMutableArray* colorIndexes;
@property(nonatomic, strong)NSMutableArray* speedArray;
@property(nonatomic, strong)NSMutableArray* kiolmeterPostArray;
@property(nonatomic, strong)NSString* lastDate;//最近的这个保存经纬度的日期
@property(nonatomic, strong)NSString* tempCurrentDate;//当天的日期年-月-日

@property (nonatomic, strong) UIButton  *  showTrackAnnotaionView;
@property (nonatomic, strong) UIButton  *  showKilometerAnnotaionView;
@property (nonatomic, weak  ) UIButton  *  runButton;
@property (nonatomic, weak  ) UIButton  *  followButton;
@property (nonatomic, weak  ) UIButton  *  correctButton;
@property (nonatomic, strong) UILabel  *   altitudeLabel;

@property (nonatomic, strong) NSArray   *  trackPoints;

@property (nonatomic, assign)MAMapType currentMapType;//当前地图的模式
@property (nonatomic, assign)LJPlayAudioType playAudioType;
@property (nonatomic, assign)BOOL needZoomAudio;


@property (nonatomic, assign) BOOL      isRun;
@property (nonatomic, assign) BOOL      isOver;
@property (nonatomic, assign) BOOL      iskilometerPost;
@property (nonatomic, assign) BOOL      showBlackBackMask;

@property (nonatomic, assign) CGFloat   distance;
@property (nonatomic, assign) CGFloat   correctDistance;
@property (nonatomic, assign) CGFloat   currentHeading;
@property (nonatomic, assign) NSInteger speedThreshold;//速度阀值

@property (nonatomic, assign) CGFloat   topSaveHeight;
@property (nonatomic, assign) CGFloat   bottomSaveHeight;

@end

@implementation LJMainViewController

- (void)viewDidLoad {
    
    if (@available(iOS 15.0, *)) {
        UITabBarAppearance* barAppearance = [[UITabBarAppearance alloc]init];
        barAppearance.backgroundColor = [UIColor whiteColor];
//        [barAppearance setShadowImage:[[UIImage alloc] init]];
//        [barAppearance setBackgroundImage:[UIImage imageNamed:@"white"]];
        self.tabBarController.tabBar.scrollEdgeAppearance = barAppearance;
        
    } else {
    }
    
    
    UIWindow* window  = [[UIApplication sharedApplication].delegate window];
    if (@available(iOS 11.0, *)) {
        self.topSaveHeight = window.safeAreaInsets.top;
        self.bottomSaveHeight = window.safeAreaInsets.bottom;
    } else {
        self.topSaveHeight = 20;
        self.bottomSaveHeight = 0;
    }
    
    
    self.playAudioType = [[[NSUserDefaults standardUserDefaults]objectForKey:@"playAudioType"]intValue];
    self.needZoomAudio = [[[NSUserDefaults standardUserDefaults]objectForKey:@"needZoomAudio"]boolValue];
    
    [super viewDidLoad];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.altitudePullView.isPullDown = NO;
    
    
//    [[LJPlayStringAudio share]setPlayContentStr:@"已经跑了 100 公里，请继续加油哦"];
    
}
-(void)dealloc{
    [LJOptionPlistFile saveArray:self.locationsArray ToPlistFile:self.lastDate];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"updateMap" object:nil];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"showTrack" object:nil];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"stop" object:nil];
}
-(void)initUI{
    self.trackInfoLabel.hidden = YES;
    self.trackInfoLabel.layer.cornerRadius = 5;
    self.trackInfoLabel.layer.masksToBounds = YES;
    
    self.mainMapView=[[MAMapView alloc]initWithFrame:CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT-20)];
    self.mainMapView.delegate=self;
    self.mainMapView.mapType = MAMapTypeStandard;
    self.mainMapView.showsUserLocation=YES;
    self.mainMapView.distanceFilter=5;
    self.mainMapView.desiredAccuracy=kCLLocationAccuracyBestForNavigation;//导航级最佳精度
    self.mainMapView.headingFilter=1;//方向变化
//    self.mainMapView.openGLESDisabled=YES;
    
    // 追踪用户的location与heading更新 MAUserTrackingModeFollowWithHeading
    [self.mainMapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    self.mainMapView.customizeUserLocationAccuracyCircleRepresentation=YES;
    
    //后台继续定位：
    self.mainMapView.pausesLocationUpdatesAutomatically=NO;
    self.mainMapView.allowsBackgroundLocationUpdates=YES;
    [self.view addSubview:self.mainMapView];
    
    
    //设置指南针位置
    self.mainMapView.compassOrigin=CGPointMake(self.mainMapView.compassOrigin.x, self.topSaveHeight+2);
    self.mainMapView.scaleOrigin=CGPointMake(self.mainMapView.scaleOrigin.x, self.topSaveHeight+2);
    
    @weakify(self);
    //定位到自己所在位置
    UIButton* locationButton=[[UIButton alloc]initWithFrame:CGRectMake(12, IPHONE_HEIGHT-100-self.bottomSaveHeight, 40, 40)];
    locationButton.layer.cornerRadius=3;
    locationButton.backgroundColor=[UIColor whiteColor];
    [locationButton setImage:[[UIImage imageNamed:@"location_yes"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [locationButton setImage:[[UIImage imageNamed:@"location_no"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    locationButton.imageView.tintColor=kSystemColor;
    [locationButton addTargetClickHandler:^(UIButton* sender, id status) {
        @strongify(self);
        if (sender.selected) {
            [self.mainMapView setMapStatus:[MAMapStatus statusWithCenterCoordinate:self.currentLocation zoomLevel:16.5 rotationDegree:0 cameraDegree:0.0f screenAnchor:CGPointMake(0.5, 0.5)] animated:YES];
        }else{
            [self.mainMapView setMapStatus:[MAMapStatus statusWithCenterCoordinate:self.currentLocation zoomLevel:16.5 rotationDegree:self.currentHeading cameraDegree:0/**  镜头下压 */ screenAnchor:CGPointMake(0.5, 0.5)] animated:YES];
        }
        sender.selected=!sender.selected;
    }];
    [self.view addSubview:locationButton];
    
    //开始运动
    LJButton_Google* runButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    runButton.frame=CGRectMake(70, IPHONE_HEIGHT-100-self.bottomSaveHeight, IPHONE_WIDTH-140, 40);
    [runButton setTitleColor:kSystemColor forState:UIControlStateNormal];
    [runButton setTitle:@"开始运动" forState:UIControlStateNormal];
    [runButton setTitle:@"正在监测..." forState:UIControlStateSelected];
    runButton.backgroundColor=[UIColor whiteColor];
    [runButton addTargetClickHandler:^(UIButton* but, id status) {
        @strongify(self);
        but.selected=!but.selected;
        if (but.selected) {
            [self startRun];
        }else{
            [self stopRun];
        }
    }];
    self.runButton=runButton;
    [self.view addSubview:runButton];
    
    //地图模式切换
    LJButton_Google* mapTypeButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    mapTypeButton.circleEffectColor=[UIColor whiteColor];
    mapTypeButton.frame=CGRectMake(IPHONE_WIDTH-129, self.topSaveHeight, 40, 40);
    mapTypeButton.layer.cornerRadius=20;
    mapTypeButton.layer.masksToBounds=YES;
    mapTypeButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [mapTypeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [mapTypeButton setTitle:@"标准" forState:UIControlStateNormal];
    mapTypeButton.backgroundColor=[UIColor blackColor];
    [mapTypeButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        self.currentMapType ++;
        if (self.currentMapType > MAMapTypeBus) {
            self.currentMapType = 0;
            [but setTitle:@"标准" forState:UIControlStateNormal];
        }else if (self.currentMapType == 1){
            [but setTitle:@"卫星" forState:UIControlStateNormal];
        }else if (self.currentMapType == 2){
            [but setTitle:@"夜间" forState:UIControlStateNormal];
        }else if (self.currentMapType == 3){
            [but setTitle:@"导航" forState:UIControlStateNormal];
        }else{
            [but setTitle:@"公交" forState:UIControlStateNormal];
        }
        self.mainMapView.mapType = self.currentMapType;
        [self.mainMapView reloadMap];
    }];
    [self.view addSubview:mapTypeButton];
    
    //是否显示 黑色的背景蒙版
    LJButton_Google* showBackMaskButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    showBackMaskButton.circleEffectColor=[UIColor whiteColor];
    showBackMaskButton.frame=CGRectMake(IPHONE_WIDTH-86, self.topSaveHeight, 40, 40);
    showBackMaskButton.layer.cornerRadius=20;
    showBackMaskButton.layer.masksToBounds=YES;
    showBackMaskButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [showBackMaskButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [showBackMaskButton setTitle:@"无蒙版" forState:UIControlStateNormal];
    [showBackMaskButton setTitle:@"蒙版" forState:UIControlStateSelected];
    showBackMaskButton.backgroundColor=[UIColor blackColor];
    [showBackMaskButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        self.showBlackBackMask = !self.showBlackBackMask;
        but.selected = self.showBlackBackMask;
        [self.mainMapView reloadMap];
        [self setBackMask];
    }];
    [self.view addSubview:showBackMaskButton];
    
    //是否播放 里程数
    LJButton_Google* playAudioButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    playAudioButton.circleEffectColor=[UIColor whiteColor];
    playAudioButton.frame=CGRectMake(IPHONE_WIDTH-86, self.topSaveHeight+44, 40, 40);
    playAudioButton.layer.cornerRadius=20;
    playAudioButton.layer.masksToBounds=YES;
    playAudioButton.titleLabel.font=[UIFont systemFontOfSize:13];
    
    playAudioButton.backgroundColor=[UIColor blackColor];
    if (self.needZoomAudio) {
        [playAudioButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    }else{
        [playAudioButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    switch (self.playAudioType) {
        case LJPlayAudioType_None:
            [playAudioButton setTitle:@"静音" forState:UIControlStateNormal];
            break;
        case LJPlayAudioType_001:
            [playAudioButton setTitle:@"10米" forState:UIControlStateNormal];
            break;
        case LJPlayAudioType_01:
            [playAudioButton setTitle:@"100米" forState:UIControlStateNormal];
            break;
        case LJPlayAudioType_1:
            [playAudioButton setTitle:@"1公里" forState:UIControlStateNormal];
            break;
    }
    @weakify(playAudioButton);
//    [playAudioButton addTargetClickHandler:^(UIButton *but, id obj) {
//        @strongify(self);
//        @strongify(playAudioButton);
//        self.playAudioType += 1;
//        if (self.playAudioType > LJPlayAudioType_1) {
//            self.playAudioType = LJPlayAudioType_None;
//        }
//        switch (self.playAudioType) {
//            case LJPlayAudioType_None:
//                [playAudioButton setTitle:@"静音" forState:UIControlStateNormal];
//                break;
//            case LJPlayAudioType_001:
//                [playAudioButton setTitle:@"10米" forState:UIControlStateNormal];
//                break;
//            case LJPlayAudioType_01:
//                [playAudioButton setTitle:@"100米" forState:UIControlStateNormal];
//                break;
//            case LJPlayAudioType_1:
//                [playAudioButton setTitle:@"1公里" forState:UIControlStateNormal];
//                break;
//        }
//    }];
    [playAudioButton addTapGestureHandler:^(UITapGestureRecognizer *tap, UIView *itself) {
        @strongify(self);
        @strongify(playAudioButton);
        self.playAudioType += 1;
        if (self.playAudioType > LJPlayAudioType_1) {
            self.playAudioType = LJPlayAudioType_None;
        }
        
        [[NSUserDefaults standardUserDefaults]setObject:@(self.playAudioType) forKey:@"playAudioType"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        switch (self.playAudioType) {
            case LJPlayAudioType_None:
                [playAudioButton setTitle:@"静音" forState:UIControlStateNormal];
                break;
            case LJPlayAudioType_001:
                [playAudioButton setTitle:@"10米" forState:UIControlStateNormal];
                break;
            case LJPlayAudioType_01:
                [playAudioButton setTitle:@"100米" forState:UIControlStateNormal];
                break;
            case LJPlayAudioType_1:
                [playAudioButton setTitle:@"1公里" forState:UIControlStateNormal];
                break;
        }
    }];
    
    [playAudioButton addMultipleTap:2 gestureHandler:^(UITapGestureRecognizer *tap, UIView *itself) {
        @strongify(self);
        @strongify(playAudioButton);
        self.needZoomAudio = !self.needZoomAudio;
        
        [[NSUserDefaults standardUserDefaults]setObject:@(self.needZoomAudio) forKey:@"needZoomAudio"];
        [[NSUserDefaults standardUserDefaults]synchronize];
        if (self.needZoomAudio) {
            [playAudioButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        }else{
            [playAudioButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }];
    [self.view addSubview:playAudioButton];
    
    
    
    //是否显示 海拔
    LJButton_Google* showAltitudeButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    showAltitudeButton.circleEffectColor=[UIColor whiteColor];
    showAltitudeButton.frame=CGRectMake(IPHONE_WIDTH-172, self.topSaveHeight, 40, 40);
    showAltitudeButton.layer.cornerRadius=20;
    showAltitudeButton.layer.masksToBounds=YES;
    showAltitudeButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [showAltitudeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [showAltitudeButton setTitle:@"海拔" forState:UIControlStateNormal];
    showAltitudeButton.backgroundColor=[UIColor blackColor];
    [showAltitudeButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        self.altitudePullView.isPullDown = !self.altitudePullView.isPullDown;
    }];
    [self.view addSubview:showAltitudeButton];
    
    self.setAccuracyView = [[NSBundle mainBundle]loadNibNamed:@"LJSetAccuracyView" owner:nil options:nil].lastObject;
    
    
    LJButton_Google* setButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    setButton.circleEffectColor=[UIColor whiteColor];
    setButton.frame=CGRectMake(20, self.topSaveHeight, 40, 40);
    setButton.layer.cornerRadius=20;
    setButton.layer.masksToBounds=YES;
    setButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [setButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [setButton setTitle:@"设置" forState:UIControlStateNormal];
    setButton.backgroundColor=[UIColor blackColor];
    [setButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        [self.setAccuracyView showPop];
    }];
    [self.view addSubview:setButton];
    
    
    self.altitudeLabel = [[UILabel alloc]initWithFrame:CGRectMake(IPHONE_WIDTH-194, self.topSaveHeight+25, 40+44, 40)];
    self.altitudeLabel.backgroundColor = [UIColor clearColor];
    self.altitudeLabel.textColor = [UIColor redColor];
    self.altitudeLabel.shadowColor = [UIColor whiteColor];
    self.altitudeLabel.highlightedTextColor = [UIColor whiteColor];
    self.altitudeLabel.font = [UIFont systemFontOfSize:12];
    self.altitudeLabel.textAlignment = NSTextAlignmentCenter;
    self.altitudeLabel.adjustsFontSizeToFitWidth = YES;
    self.altitudeLabel.text = nil;
    [self.view addSubview:self.altitudeLabel];
    
    //是否随着 位置的移动，地图跟着动。
    LJButton_Google* followButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    followButton.circleEffectColor=[UIColor whiteColor];
    followButton.frame=CGRectMake(IPHONE_WIDTH-43, self.topSaveHeight+44, 40, 40);
    followButton.layer.cornerRadius=20;
    followButton.layer.masksToBounds=YES;
    followButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [followButton setTitle:@"跟踪" forState:UIControlStateNormal];
    [followButton setTitle:@"追踪中" forState:UIControlStateSelected];
    followButton.backgroundColor=[UIColor blackColor];
    [followButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        but.selected=!but.selected;
        if (but.selected) {
            [self.mainMapView setCenterCoordinate:self.currentLocation animated:YES];
            [self.mainMapView setRotationDegree:self.currentHeading animated:YES duration:0.2];

        }
    }];
    self.followButton=followButton;
    [self.view addSubview:followButton];
    
    //路径 纠偏按钮，效果不是很好。。。
    LJButton_Google* correctButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    correctButton.circleEffectColor=[UIColor whiteColor];
    correctButton.frame=CGRectMake(IPHONE_WIDTH-43, self.topSaveHeight+88, 40, 40);
    correctButton.layer.cornerRadius=20;
    correctButton.layer.masksToBounds=YES;
    correctButton.titleLabel.font=[UIFont systemFontOfSize:13];
    [correctButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [correctButton setTitle:@"纠偏" forState:UIControlStateNormal];
    [correctButton setTitle:@"完成" forState:UIControlStateSelected];
    correctButton.backgroundColor=[UIColor blackColor];
    [correctButton addTargetClickHandler:^(UIButton *but, id obj) {
        @strongify(self);
        but.selected=!but.selected;
        if (but.selected) {
            [self correctTrack];
        }
    }];
    self.correctButton=correctButton;
    [self.view addSubview:correctButton];
    self.correctButton.hidden = YES;
    
    //是否显示 定位点详细信息的大头针
    _showTrackAnnotaionView=[[UIButton alloc]initWithFrame:CGRectMake(IPHONE_WIDTH-50, IPHONE_HEIGHT-100-self.bottomSaveHeight, 40, 40)];
    _showTrackAnnotaionView.layer.cornerRadius=3;
    _showTrackAnnotaionView.backgroundColor=[UIColor whiteColor];
    [_showTrackAnnotaionView setImage:[[UIImage imageNamed:@"but_Pin"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_showTrackAnnotaionView setImage:[[UIImage imageNamed:@"but_Pin"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    [_showTrackAnnotaionView setImageEdgeInsets:UIEdgeInsetsMake(10, 0, -10, 0)];
    _showTrackAnnotaionView.imageView.tintColor=[UIColor lightGrayColor];
    [_showTrackAnnotaionView addTargetClickHandler:^(UIButton* sender, id status) {
        @strongify(self);
        sender.selected=!sender.selected;
        if (sender.selected) {
            sender.imageView.tintColor=kSystemColor;
        }else{
            sender.imageView.tintColor=[UIColor lightGrayColor];
        }
        [self showTrackAnnotation:sender.selected];
    }];
    [self.view addSubview:_showTrackAnnotaionView];
    _showTrackAnnotaionView.hidden=YES;
    
    //是否显示 每公里标识的大头针
    _showKilometerAnnotaionView=[[UIButton alloc]initWithFrame:CGRectMake(IPHONE_WIDTH-50, IPHONE_HEIGHT-100-45-self.bottomSaveHeight, 40, 40)];
    _showKilometerAnnotaionView.layer.cornerRadius=3;
    _showKilometerAnnotaionView.backgroundColor=[UIColor whiteColor];
    [_showKilometerAnnotaionView setImage:[[UIImage imageNamed:@"vip_menu_list_address"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_showKilometerAnnotaionView setImage:[[UIImage imageNamed:@"vip_menu_list_address"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    _showKilometerAnnotaionView.imageView.tintColor=[UIColor lightGrayColor];
    [_showKilometerAnnotaionView addTargetClickHandler:^(UIButton* sender, id status) {
        @strongify(self);
        sender.selected=!sender.selected;
        if (sender.selected) {
            sender.imageView.tintColor=kSystemColor;
        }else{
            sender.imageView.tintColor=[UIColor lightGrayColor];
        }
        [self showKilometerPostAnnotation:sender.selected];
    }];
    [self.view addSubview:_showKilometerAnnotaionView];
    _showKilometerAnnotaionView.hidden=YES;
    
    //海拔曲线
    LJPullDownView* pullView = [LJPullDownView sharePullDownViewWithFrame:CGRectMake(0, self.topSaveHeight+44, IPHONE_WIDTH, IPHONE_WIDTH/2.0)];
    self.altitudePullView = pullView;
    self.altitudeLineView = [[WSLineChartView alloc]initWithFrame:CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_WIDTH/2.0)];
    self.altitudeLineView.lineColor = [UIColor redColor];
    self.altitudeLineView.emptyBackImage = [UIImage imageNamed:@"china"];
    self.altitudeLineView.emptyLabelColor = [UIColor whiteColor];
    self.altitudeLineView.showEmptyImageView = YES;
    self.altitudeLineView.backgroundColor = [[UIColor brownColor]colorWithAlphaComponent:1];
    self.altitudePullView.pullDownContentView = self.altitudeLineView;
    
    //延迟0.35秒， 定位到所在的位置
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.currentLocation.latitude>0.01) {
            [self.mainMapView setZoomLevel:15 animated:NO];
            [self.mainMapView setCenterCoordinate:self.currentLocation animated:YES];
            [self.mainMapView setRotationDegree:self.currentHeading animated:YES duration:0.2];
        }
    });
}

-(void)initData{
    self.speedThreshold = 10;
    self.locationsArray=[NSMutableArray array];
    self.colorArray=[NSMutableArray array];
    self.colorIndexes=[NSMutableArray array];
    self.trackColorArray=[NSMutableArray array];
    self.speedArray=[NSMutableArray array];
    self.kiolmeterPostArray=[NSMutableArray array];
    
    /**  设置轨迹颜色 */
    [self.colorArray addObject:kRGBColorf(0.9, 1, 0.3, 1)];
    for (NSInteger i=1; i<=10; i++) {
        UIColor* lineColor=kRGBColorf(0.9, (1 - i/10.0f), 0.3, 1);
        [self.colorArray addObject:lineColor];
    }
    
    @weakify(self);
    [[NSNotificationCenter defaultCenter]addObserverName:@"updateMap" object:nil handler:^(id sender, id status) {
        @strongify(self);
        [self.mainMapView reloadMap];
        DLog(@"🏃。。。。");
    }];
    [[NSNotificationCenter defaultCenter]addObserverName:@"showTrack" object:nil handler:^(NSNotification* sender, id status) {
        @strongify(self);
        DLog(@"⌚️：%@", sender.object);
        if ([sender.object isEqualToString:@"canShow"]) {
            [[NSNotificationCenter defaultCenter]postNotificationName:@"canShow" object:@(self.isRun)];
        }else{
            [self stopRun];
            self.isOver=NO;
            self.runButton.selected=NO;
            [self showTrackTime:sender.object isUpdate:NO];
        }
    }];
    [[NSNotificationCenter defaultCenter]addObserverName:@"showTrackAbove" object:nil handler:^(NSNotification* sender, id status) {
        @strongify(self);
        [self stopRun];
        self.isOver=YES;
        self.runButton.selected=NO;
        [self showTrackTime:sender.object isUpdate:NO];
    }];
    
    [[NSNotificationCenter defaultCenter]addObserverName:@"stop" object:nil handler:^(id sender, id status) {
       @strongify(self);
        [self initDate];
    }];
}

/**  初始化 时间 */
-(void)initDate{
    NSArray* dateList=[LJOptionPlistFile readPlistFile:dateListName];
    NSString* currentDate=[TimeTools getCurrentTimesType:@"yyyy-MM-dd"];
    self.tempCurrentDate=currentDate;
    if (dateList) {
        if (![currentDate isEqualToString:dateList.firstObject]) {
            NSArray* separateName=[dateList.firstObject componentsSeparatedByString:@"."];
            if (!separateName || (separateName && ![currentDate isEqualToString:separateName.firstObject])) {
                //保存新的一天的第一个日期
                [LJOptionPlistFile saveObject:currentDate ToPlistFile:dateListName inHead:YES];
                self.lastDate=currentDate;
            }else{
                //当天里面最近的那个日期
                //self.locationsArray=[NSMutableArray arrayWithArray:[LJOptionPlistFile readPlistFile:dateList.firstObject]];
                self.lastDate=dateList.firstObject;
            }
        }else{
            //当天里面唯一的那个日期
            //self.locationsArray=[NSMutableArray arrayWithArray:[LJOptionPlistFile readPlistFile:dateList.firstObject]];
            self.lastDate=dateList.firstObject;
        }
    }else{
        //程序第一个开始的日期
        [LJOptionPlistFile saveArray:@[currentDate] ToPlistFile:dateListName];
        self.lastDate=currentDate;
    }
}

/**  显示区域改变的时候 刷新背景蒙版 */
-(void)setBackMask{
    if (!self.showBlackBackMask) {
        for (id <MAOverlay> overlays in self.mainMapView.overlays) {
            if (self.backMaskPolygon == overlays) {
                [self.mainMapView removeOverlay:self.backMaskPolygon];
            }
        }
        return;
    }
    CGFloat width = self.view.lj_width;
    CGFloat height = self.view.lj_height;
    
    CLLocationCoordinate2D leftTop =[self.mainMapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self.view];
    CLLocationCoordinate2D rightTop =[self.mainMapView convertPoint:CGPointMake(width, 0) toCoordinateFromView:self.view];
    CLLocationCoordinate2D leftBottom =[self.mainMapView convertPoint:CGPointMake(0, height) toCoordinateFromView:self.view];
    CLLocationCoordinate2D rightBottom =[self.mainMapView convertPoint:CGPointMake(width, height) toCoordinateFromView:self.view];
    CLLocationCoordinate2D  pointCoords[4];
    CGFloat offset = self.mainMapView.zoomLevel > 10 ? 1 : 0; //根据地图的缩放 设置蒙版的边缘
    
    pointCoords[0] = CLLocationCoordinate2DMake(leftTop.latitude+offset, leftTop.longitude-offset);
    pointCoords[1] = CLLocationCoordinate2DMake(rightTop.latitude-offset, rightTop.longitude-offset);
    
    pointCoords[3] = CLLocationCoordinate2DMake(leftBottom.latitude+offset, leftBottom.longitude+offset);
    pointCoords[2] = CLLocationCoordinate2DMake(rightBottom.latitude-offset, rightBottom.longitude+offset);
    
    if (self.backMaskPolygon) {
        [self.mainMapView removeOverlay:self.backMaskPolygon];
    }
    
    MAPolygon* polygon = [MAPolygon polygonWithCoordinates:pointCoords count:4];
    self.backMaskPolygon = polygon;
    [self.mainMapView insertOverlay:self.backMaskPolygon atIndex:0 level:MAOverlayLevelAboveRoads];
}


#pragma mark - ================ Delegate ==================
//请求权限   iOS 11及以上版本使用后台定位服务, 需要实现
-(void)mapViewRequireLocationAuth:(CLLocationManager *)locationManager{
    
    [locationManager requestAlwaysAuthorization];
}

/**  位置更新，得到经纬度 */
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    DLog(@"speed:%.2f, accuracyH:%.2f, accuracyV:%.2f", userLocation.location.speed, userLocation.location.horizontalAccuracy, userLocation.location.verticalAccuracy);
    self.altitudeLabel.text = [NSString stringWithFormat:@"%.1f米", userLocation.location.altitude];
    self.setAccuracyView.location = userLocation.location;
    
    if (updatingLocation) {
        if (self.isRun) {
            //过滤 相同经纬度的点
            if (self.currentLocation.latitude != userLocation.coordinate.latitude &&
                self.currentLocation.longitude != userLocation.coordinate.longitude) {
                //过滤 精度不高的点 和 没有速度或者速度过高的点。
                if (userLocation.location.speed*3.6 >= self.setAccuracyView.minSpeedSlider.value &&
                    (userLocation.location.speed*3.6 <= self.setAccuracyView.maxSpeedSlider.value ||
                     self.setAccuracyView.maxSpeedSlider.value > 150) &&
                    
                    userLocation.location.horizontalAccuracy<=self.setAccuracyView.horizontalSlider.value &&
                    userLocation.location.horizontalAccuracy>0 &&
                    userLocation.location.verticalAccuracy<=self.setAccuracyView.verticalSlider.value &&
                    userLocation.location.verticalAccuracy>0) {
                    
                    [self saveLocation:userLocation];
                    [self showTrackTime:self.lastDate isUpdate:YES];
                }
            }
        }
        if(self.followButton.selected){
            [self.mainMapView setCenterCoordinate:userLocation.coordinate animated:YES];
            [self.mainMapView setRotationDegree:self.currentHeading animated:YES duration:0.2];
        }
        DLog(@"latitude: %f, longitude: %f heading:%f %f %f \n%@", userLocation.coordinate.latitude, userLocation.coordinate.longitude, userLocation.heading.magneticHeading, userLocation.heading.trueHeading, userLocation.heading.headingAccuracy, userLocation.heading);
    }else{//head 只是设备的方向，地图旋转后 这个head方向并不会改变，只有设备旋转才会改变
        self.currentHeading=userLocation.heading.trueHeading;
        UIImage* image=[UIImage imageNamed:@"direction"];
        image=[LJImageTools rotationImage:image angle:self.currentHeading-mapView.rotationDegree clip:YES];
        _annotationView.image=image;
        
        if(self.followButton.selected){
            [self.mainMapView setCenterCoordinate:userLocation.coordinate animated:YES];
            [self.mainMapView setRotationDegree:self.currentHeading animated:YES duration:0.2];
        }
        DLog(@"heading: %f --%f -- %f", userLocation.heading.trueHeading, userLocation.heading.magneticHeading, userLocation.heading.headingAccuracy);
    }
    self.currentLocation=userLocation.coordinate;
    self.currentLocationInfo = userLocation;
}

/**  因为无法监听地图的方向rotationDegree 的值，所以就当做旋转地图时，或多或少会改变地图大小 */
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    [self setBackMask];
    UIImage* image=[UIImage imageNamed:@"direction"];
    image=[LJImageTools rotationImage:image angle:self.currentHeading-mapView.rotationDegree clip:YES];
    _annotationView.image=image;
    DLog(@"zoom.... %f", mapView.rotationDegree);
}

/**  自定义精度圈样式  边框和填充色 , 设置折线样式*/
-(MAOverlayRenderer*)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if (overlay == mapView.userLocationAccuracyCircle) {
        //精度圈
        MACircleRenderer* accuracyCircleRenderer = [[MACircleRenderer alloc]initWithCircle:overlay];
        accuracyCircleRenderer.lineWidth=2.0f;
        accuracyCircleRenderer.strokeColor=[[UIColor redColor] colorWithAlphaComponent:0.4];
        accuracyCircleRenderer.fillColor=[UIColor colorWithRed:1 green:0 blue:0 alpha:0.2];
        return accuracyCircleRenderer;
    }else if ([overlay isKindOfClass:[MAMultiPolyline class]]){
        //折线样式
        MAMultiColoredPolylineRenderer* colorLineView=[[MAMultiColoredPolylineRenderer alloc]initWithOverlay:overlay];
        colorLineView.lineWidth=8.0f;
        colorLineView.strokeColors=self.trackColorArray;
        colorLineView.gradient=!self.correctButton.selected;
        colorLineView.lineJoinType=kMALineJoinRound;//连接类型
        colorLineView.lineCapType=kMALineCapRound;//端点类型
        return colorLineView;
    }else if ([overlay isKindOfClass:[MAPolygon class]]){
        MAPolygonRenderer* renderer = [[MAPolygonRenderer alloc]initWithPolygon:(MAPolygon*)overlay];
        renderer.fillColor = [[UIColor blackColor]colorWithAlphaComponent:0.55];
        return  renderer;
    }
    return nil;
}

/**  自定义定位点样式, 大头针样式 */
-(MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        //定位点
        _annotationView=[mapView dequeueReusableAnnotationViewWithIdentifier:userLocationStyleReuseIndetifier];
        if (!_annotationView) {
            _annotationView=[[MAAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:userLocationStyleReuseIndetifier];
            _annotationView.image=[UIImage imageNamed:@"index_bottom_brand_active"];
        }
        return _annotationView;
    }else if ([annotation isKindOfClass:[MAPointAnnotation class]]){
        //大头针：
        MAPointAnnotation* pointAnnotation = annotation;
        NSString* identifier = pointReuseIndentifier;
        if (self.iskilometerPost && ([pointAnnotation.subtitle isEqualToString:kilometerIndentifier])) {
            identifier = kilometerIndentifier;
        }else if ([pointAnnotation.subtitle isEqualToString:@"start"] || [pointAnnotation.subtitle isEqualToString:@"end"]){
            identifier = @"startEnd";
        }
        
        MAPinAnnotationView* annotationView=(MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!annotationView) {
            annotationView=[[MAPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.canShowCallout=YES;  //设置气泡弹出，默认NO
            annotationView.animatesDrop=YES;    //动画效果，默认NO
            annotationView.image = nil;
            annotationView.pinColor=MAPinAnnotationColorPurple;
            annotationView.lj_size=CGSizeMake(30, 30);
            
            if (self.iskilometerPost && [identifier isEqualToString:kilometerIndentifier]) {
                annotationView.centerOffset = CGPointMake(0, -12.5);
                annotationView.enabled = NO;
            }
            if ([identifier isEqualToString:@"startEnd"]) {
                annotationView.zIndex = 10;
                if ([pointAnnotation.subtitle isEqualToString:@"start"]){
                    annotationView.centerOffset = CGPointMake(-4, -10);
                }else{
                    annotationView.centerOffset = CGPointMake(9.5, -10);
                }
                annotationView.enabled = NO;
            }else{
                annotationView.zIndex = 0;
            }
        }
        
        if ([pointAnnotation.subtitle isEqualToString:@"start"]) {
            annotationView.image = [UIImage imageNamed:@"iconStart"];
        }else if ([pointAnnotation.subtitle isEqualToString:@"end"]){
            annotationView.image = [UIImage imageNamed:@"endPoint"];
        }
        
        if (self.iskilometerPost && [pointAnnotation.subtitle isEqualToString:kilometerIndentifier]) {
            
            [annotationView setLabelText:pointAnnotation.title font:[UIFont boldSystemFontOfSize:12] color:[UIColor greenColor]];
            annotationView.image = [UIImage imageNamed:@"redKilometerPin"];
//            annotationView.pinColor=MAPinAnnotationColorRed;
        }
        
        return annotationView;
    }
    return nil;
}

-(void)offlineDataDidReload:(MAMapView *)mapView{
    DLog(@"👨已经加载离线地图了");
}

/**  点击地图，获取POI信息 */
//-(void)mapView:(MAMapView *)mapView didTouchPois:(NSArray *)pois
//{
//    DLog(@"👨不要点我啦");
//}

#pragma mark - ================ Action ==================
-(void)startRun{
    if (self.playAudioType != LJPlayAudioType_None) {
        [LJPlayStringAudio share].needZoomInAudio = self.needZoomAudio;
        [[LJPlayStringAudio share]setPlayContentStr:@"开始运动啦"];
    }
    self.trackInfoLabel.hidden = YES;
    self.title=[NSString stringWithFormat:@"总路程0.0公里"];
    self.isRun=YES;
    self.isOver=NO;
    [self initDate];
    
    [self.colorIndexes removeAllObjects];
    [self.trackColorArray removeAllObjects];
    [self.speedArray removeAllObjects];
    [self.kiolmeterPostArray removeAllObjects];
    self.distance=0.0f;
    self.iskilometerPost = NO;
    
    [self.mainMapView setCenterCoordinate:self.currentLocation animated:YES];
    [self.mainMapView setRotationDegree:self.currentHeading animated:YES duration:0.2];
    
    for (id<MAOverlay> line in self.mainMapView.overlays) {
        if ([line isKindOfClass:[MAPolyline class]]) {
            [self.mainMapView removeOverlay:line];
        }
    }
    for (id<MAAnnotation> view in self.mainMapView.annotations) {
        if (![view isKindOfClass:[MAUserLocation class]]) {
            [self.mainMapView removeAnnotation:view];
        }
    }
    
    NSArray* array=[LJOptionPlistFile readPlistFile:self.lastDate];
    if (array.count<1) {
        //第一个时间为空， 则直接使用该时间
        [self.locationsArray removeAllObjects];
        [self saveLocation:self.currentLocationInfo];
        return;
    }
    
    //第一个时间 里面的定位点不为空，则再加一个时间
    NSString* lastName=nil;
    NSArray* separateName=[self.lastDate componentsSeparatedByString:@"."];
    if (separateName && separateName.count>1) {
        lastName=[NSString stringWithFormat:@"%@.%ld",separateName.firstObject, (long)([[separateName lastObject] integerValue]+1)];
    }else{
        lastName=[NSString stringWithFormat:@"%@.1",self.lastDate];
    }
    [LJOptionPlistFile saveObject:lastName ToPlistFile:dateListName inHead:YES];
    self.lastDate=lastName;
    
    
    [self.locationsArray removeAllObjects];
}

-(void)stopRun{
    self.isRun=NO;
}

-(void)saveLocation:(MAUserLocation*)location
{
    NSString* timestamp=[TimeTools getCurrentTimestamp];
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    NSArray* tempLocation = @[timestamp, @(coordinate.latitude),@(coordinate.longitude), @(location.location.altitude)];
    [LJOptionPlistFile saveObject:tempLocation ToPlistFile:self.lastDate inHead:NO];
    [self.locationsArray addObject:tempLocation];
}

/**  update 表示正在运动中，一直更新。 */
-(void)showTrackTime:(NSString*)timeStr isUpdate:(BOOL)update
{
    
    NSArray* array = nil;
    if (update) {
        self.correctDistance = 0;
        array = [NSArray arrayWithArray:self.locationsArray];
    }else{
        if (!timeStr) {//表示 路径纠偏
            array = [NSArray arrayWithArray:self.locationsArray];
        }else{
            self.correctDistance = 0;
            array = [LJOptionPlistFile readPlistFile:timeStr];
            [self showAltitudeArray:array];
            self.locationsArray = [NSMutableArray arrayWithArray:array];
            if (array.count>5) {
                self.correctButton.hidden = NO;
                self.correctButton.selected = NO;
            }
        }
    }
    
    if (array.count<2) {
        return;
    }
    
    //删除 路径图层
    if (!self.isOver) {
        for (id<MAOverlay> line in self.mainMapView.overlays) {
            if ([line isKindOfClass:[MAPolyline class]]) {
                [self.mainMapView removeOverlay:line];
            }
        }
    }
    
    self.trackPoints=array;
    self.showTrackAnnotaionView.hidden=NO;
    //路径点
    CLLocationCoordinate2D commonPolylineCoords[array.count];
    
    if (!update || array.count ==2) {
        [self.colorIndexes removeAllObjects];
        [self.trackColorArray removeAllObjects];
        [self.speedArray removeAllObjects];
        
        if (!self.isOver) {
            
            self.distance=0.0f;
            [self.kiolmeterPostArray removeAllObjects];
            
            //删除 公里里程标，
            for (id<MAAnnotation> view in self.mainMapView.annotations) {
                if (![view isKindOfClass:[MAUserLocation class]]) {
                    [self.mainMapView removeAnnotation:view];
                }
            }
        }
        
        //不是运动状态  设置 路径点
        for (NSInteger i=0; i<array.count; i++) {
            NSArray* location=array[i];
            commonPolylineCoords[i].latitude=[location[1] floatValue];
            commonPolylineCoords[i].longitude=[location[2] floatValue];
        }
        [self.trackColorArray addObject:[UIColor orangeColor]];
        [self.colorIndexes addObject:@0];
        for (NSInteger i=1; i<array.count; i++) {
            NSArray* location=array[i];
            NSArray* frontLocation=array[i-1];
            
            //计算距离
            double time=fabs([location[0] doubleValue]-[frontLocation[0] doubleValue]);
            MAMapPoint point1=MAMapPointForCoordinate(commonPolylineCoords[i-1]);
            MAMapPoint point2=MAMapPointForCoordinate(commonPolylineCoords[i]);
            CLLocationDistance distance=MAMetersBetweenMapPoints(point1,point2);
            
            DLog(@"distance:%.4f", distance);
            //添加里程坐标
            NSInteger oneDistance = (NSInteger)self.distance/1000;
            self.distance+=distance;
            NSInteger twoDistance = (NSInteger)self.distance/1000;
            if (twoDistance - oneDistance >0.01) {
                [self.kiolmeterPostArray addObject:location];
            }
            
            //计算速度
            NSInteger speed= (distance<0.01 || time<0.01) ? 0 : (NSInteger)distance/time;
            NSInteger index = (speed>=10) ? 10 : (speed%10);
//            NSInteger index = (speed>=_speedThreshold) ? 10 : (speed/_speedThreshold*10);
            CGFloat tempSpeed=time==0 || distance==0 ? 0 : distance/time;
            [self.speedArray addObject:@(tempSpeed)];
            
            //根据速度 计算颜色
            if (!timeStr) {
                [self.trackColorArray addObject:self.colorArray.lastObject];
            }else{
                [self.trackColorArray addObject:self.colorArray[index]];
            }
            
            [self.colorIndexes addObject:@(i)];
        }
        
        
    }else{
        //运动状态  设置 路径点
        for (NSInteger i=0; i<array.count; i++) {
            NSArray* location=array[i];
            commonPolylineCoords[i].latitude=[location[1] floatValue];
            commonPolylineCoords[i].longitude=[location[2] floatValue];
        }
        
        for (NSInteger i = array.count - 1; i<array.count; i++) {
            NSArray* location=array[i];
            NSArray* frontLocation=array[i-1];
            
            //计算距离
            double time=fabs([location[0] doubleValue]-[frontLocation[0] doubleValue]);
            MAMapPoint point1=MAMapPointForCoordinate(commonPolylineCoords[i-1]);
            MAMapPoint point2=MAMapPointForCoordinate(commonPolylineCoords[i]);
            CLLocationDistance distance=MAMetersBetweenMapPoints(point1,point2);
            self.distance+=distance;
            
            //计算速度
            NSInteger speed= (distance<0.01 || time<0.01) ? 0 : (NSInteger)distance/time;
            NSInteger index = (speed>=10) ? 10 : (speed%10);
//            NSInteger index = (speed>=_speedThreshold) ? 10 : (speed/_speedThreshold*10);
            CGFloat tempSpeed=time==0 || distance==0 ? 0 : distance/time;
            [self.speedArray addObject:@(tempSpeed)];
            
            //根据速度 计算颜色
            [self.trackColorArray addObject:self.colorArray[index]];
            [self.colorIndexes addObject:@(i)];
        }
        
        NSString* distanceStr = @"";
        switch (self.playAudioType) {
            case LJPlayAudioType_None:
                distanceStr = @"";
                break;
            case LJPlayAudioType_001:
                //按10米等级 来播报
                if (self.distance >= 10 && self.distance < 100) {
                    distanceStr = [NSString stringWithFormat:@"%d米",((int)self.distance/10)*10];
                }
                break;
            case LJPlayAudioType_01:
                if (self.distance < 1000 && self.distance >= 100) {
                    //不到1公里的，播报 百米数
                    distanceStr = [NSString stringWithFormat:@"%ld百米",((NSInteger)self.distance/100)];
                }else if(self.distance >= 1000){
                    distanceStr = [NSString stringWithFormat:@"%.1f公里",((NSInteger)self.distance/100)/10.0];
                }
                break;
            case LJPlayAudioType_1:
                if (self.distance >= 1000) {
                    distanceStr = [NSString stringWithFormat:@"%ld公里",(NSInteger)self.distance/1000];
                }
                break;
        }
        if (self.playAudioType != LJPlayAudioType_None && distanceStr.length > 1) {
            if (![[LJPlayStringAudio share].playContentStr isEqualToString:distanceStr]) {
                [LJPlayStringAudio share].needZoomInAudio = self.needZoomAudio;
                [[LJPlayStringAudio share]setPlayContentStr:distanceStr];
            }
        }
    }
    
    self.title=[NSString stringWithFormat:@"里程%.2f公里",self.distance/1000.0];
    if (self.correctDistance > 0.01) {
        self.title=[NSString stringWithFormat:@"里程%.2f公里",self.correctDistance/1000.0];
    }
    if (self.locationsArray.count > 1 && !self.isOver) {
        self.trackInfoLabel.hidden = NO;
        [self.view bringSubviewToFront:self.trackInfoLabel];
        NSArray* array = self.locationsArray;
        NSString* startTime=[TimeTools timestampChangesStandarTime:array[array.count-1][0] Type:@"HH:mm:ss"];
        NSString* endTime=[TimeTools timestampChangesStandarTime:array[0][0] Type:@"HH:mm:ss"];
        
        long intervalStart=(long)[array[0][0] longLongValue];
        long intervalEnd=(long)[array[array.count-1][0] longLongValue];
        
        long intervalTime=labs(intervalStart-intervalEnd);
        NSString* time=[TimeTools timestampChangesStandarTime:[NSString stringWithFormat:@"%ld",intervalTime] Type:@"HH:mm:ss"];
        
        self.trackInfoLabel.text = [NSString stringWithFormat:@"\n %@\n\n 耗时: %@\n 时间: %@ ~ %@ \n\n 配速: %.2f km/h\n 里程: %.2f km\n",timeStr, time, startTime, endTime, ((self.distance/1000.0)/(intervalTime/3600.0)), self.distance/1000.0];
    }else{
        self.trackInfoLabel.text = nil;
        self.trackInfoLabel.hidden = YES;
    }
    
    //构造折线对象
    MAMultiPolyline* commonPolyline =[MAMultiPolyline polylineWithCoordinates:commonPolylineCoords count:array.count drawStyleIndexes:self.colorIndexes];
    
    [self.mainMapView addOverlay:commonPolyline];
    if(self.followButton.selected || !update){
        [self.mainMapView setCenterCoordinate:commonPolylineCoords[array.count-1] animated:YES];
    }
    if (self.isOver || !update) {
        self.showKilometerAnnotaionView.hidden = NO;
        self.showKilometerAnnotaionView.selected = YES;
        self.showKilometerAnnotaionView.imageView.tintColor=kSystemColor;
        [self showKilometerPostAnnotation:YES];
        [self showStartAndEndAnnotation];
    }else{
        self.showKilometerAnnotaionView.hidden = YES;
        self.showKilometerAnnotaionView.selected = NO;
        self.showKilometerAnnotaionView.imageView.tintColor=[UIColor lightGrayColor];
    }
}


/**  路径 纠偏，绘制一条平滑轨迹 */
-(void)correctTrack{
    MATraceManager* manager = [[MATraceManager alloc]init];
    NSMutableArray* traceArray = [NSMutableArray new];
    for (NSArray* subArray in self.locationsArray) {
        CGFloat latitude=[subArray[1] floatValue];
        CGFloat longitude=[subArray[2] floatValue];
        MATraceLocation* location = [[MATraceLocation alloc]init];
        location.loc = CLLocationCoordinate2DMake(latitude, longitude);
        //location.time = [subArray[0] floatValue];
        [traceArray addObject:location];
    }
    @weakify(self);
    [manager queryProcessedTraceWith:traceArray type:-1 processingCallback:^(int index, NSArray<MATracePoint *> *points) {
        @strongify(self);
        self.correctButton.hidden = YES;
    } finishCallback:^(NSArray<MATracePoint *> *points, double distance) {
        @strongify(self);
        DLog(@".. 纠偏完成");
        if (points.count) {
            NSMutableArray* tempLocations = [NSMutableArray array];
            CGFloat multiple = self.locationsArray.count / (CGFloat)points.count;
            [points enumerateObjectsUsingBlock:^(MATracePoint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSInteger index = multiple * idx;
                NSArray* subLocation = @[self.locationsArray[index][0], @(obj.latitude), @(obj.longitude)];
                [tempLocations addObject:subLocation];
                
            }];
            self.locationsArray = [NSMutableArray arrayWithArray:tempLocations];
            self.correctButton.hidden = YES;
            self.correctDistance = distance;
            [self showTrackTime:nil isUpdate:NO];
        }
        
    } failedCallback:^(int errorCode, NSString *errorDesc) {
        DLog(@"..纠偏失败%@", errorDesc);
        @strongify(self);
        self.correctButton.hidden = YES;
    }];
    
}

/**  显示 公里里程 大头针 */
-(void)showKilometerPostAnnotation:(BOOL)isShow{
    self.iskilometerPost = isShow;
    if (isShow) {//显示 公里标识大头针
        for (NSInteger i=0; i<self.kiolmeterPostArray.count; i++) {
            
            NSArray* location=self.kiolmeterPostArray[i];
            CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] floatValue], [location[2] floatValue]);
            MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
            
            pointAnnotation.coordinate = coordinate;
            pointAnnotation.title = [NSString stringWithFormat:@"%ld", i+1];
            pointAnnotation.subtitle = kilometerIndentifier;
            [self.mainMapView addAnnotation:pointAnnotation];
        }
    }else{//删除  公里标识大头针
        for (id<MAAnnotation> view in self.mainMapView.annotations) {
            if ([view.subtitle isEqualToString:kilometerIndentifier]) {
                [self.mainMapView removeAnnotation:view];
            }
        }
    }
}

/**  显示 开始结束 大头针 */
-(void)showStartAndEndAnnotation{
    if (self.trackPoints.count > 1) {
        {//start point
            NSArray* location=self.trackPoints.firstObject;
            CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] floatValue], [location[2] floatValue]);
            MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
            pointAnnotation.coordinate = coordinate;
            pointAnnotation.title = @"start";
            pointAnnotation.subtitle=@"start";
            [self.mainMapView addAnnotation:pointAnnotation];
        }
        {//end point
            NSArray* location=self.trackPoints.lastObject;
            CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] floatValue], [location[2] floatValue]);
            MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
            pointAnnotation.coordinate = coordinate;
            pointAnnotation.title = @"end";
            pointAnnotation.subtitle=@"end";
            [self.mainMapView addAnnotation:pointAnnotation];
        }
    }
}

/**  显示 路径上的 详细数据 大头针 */
-(void)showTrackAnnotation:(BOOL)show{
    
    if (show) {
        NSInteger multiple = 5;
        //最多显示 100 的定位标， 太多 会有卡顿
        if (self.trackPoints.count /multiple > 100) {
            multiple = self.trackPoints.count / 100;
        }
        
        for (NSInteger i=0; i<self.trackPoints.count-1; i++) {
            if (i%multiple==0) {
                
                NSArray* location=self.trackPoints[i];
                CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] doubleValue], [location[2] doubleValue]);
                
                MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
                pointAnnotation.coordinate = coordinate;
                pointAnnotation.title = [TimeTools timestampChangesStandarTime:location[0]];
                if (location.count > 3) {//新版本 有海拔高度的
                    double altitude = 0;
                    altitude = [location[3] doubleValue];
                    pointAnnotation.subtitle=[NSString stringWithFormat:@"速度:%.2fkm/h 海拔:%.2fm", [self.speedArray[i] floatValue]/1000*3600, altitude];
                }else{
                    pointAnnotation.subtitle=[NSString stringWithFormat:@"速度:%.2fkm/h", [self.speedArray[i] floatValue]/1000*3600];
                }
                [self.mainMapView addAnnotation:pointAnnotation];
            }
        }
        
    }else{
        for (id<MAAnnotation> view in self.mainMapView.annotations) {
            if (![view isKindOfClass:[MAUserLocation class]]) {
                if ([view.subtitle hasPrefix:@"速度"]) {
                    [self.mainMapView removeAnnotation:view];
                }
            }
        }
//        [self showStartAndEndAnnotation];
//        [self showKilometerPostAnnotation:self.showKilometerAnnotaionView.selected];
    }
}

/**  显示海拔 曲线图 */
-(void)showAltitudeArray:(NSArray*)dataArray{
    NSMutableArray* xTimeTitleArray = [NSMutableArray array];
    NSMutableArray* yValueArray = [NSMutableArray array];
    CGFloat yMax = 0;
    CGFloat yMin = 0;
    
    for (NSArray* altitudeArray in dataArray) {
        if (altitudeArray.count > 3) {
            
            CGFloat altitude = [altitudeArray[3] floatValue];
            if (yMax < altitude) {
                yMax = altitude;
            }
            if (yMin > altitude) {
                yMin = altitude;
            }
            
            NSString* timeStr = [TimeTools timestampChangesStandarTime:altitudeArray[0] Type:@"HH\nmm"];
            NSString* altitudeStr = [NSString stringWithFormat:@"%.2f", altitude];
            [xTimeTitleArray addObject:timeStr];
            [yValueArray addObject:altitudeStr];
        }
    }
    
    [self.altitudeLineView setxTitleArray:xTimeTitleArray yValueArray:yValueArray yMax:yMax yMin:yMin xUnit:@"时间" yUnit:@"海拔" animation:NO];
    if (yValueArray.count > 1) {
        self.altitudePullView.isPullDown = YES;
    }
}

@end
