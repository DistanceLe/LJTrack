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

#import "TimeTools.h"
#import "LJImageTools.h"
#import "LJOptionPlistFile.h"

@interface LJMainViewController ()<MAMapViewDelegate>

@property(nonatomic, strong)MAMapView* mainMapView;
@property(nonatomic, strong)MAAnnotationView* annotationView;
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
@property (nonatomic, weak  ) UIButton  *  runButton;
@property (nonatomic, weak  ) UIButton  *  followButton;
@property (nonatomic, weak  ) UIButton  *  correctButton;
@property (nonatomic, strong) NSArray   *  trackPoints;
@property (nonatomic, assign) BOOL      isRun;
@property (nonatomic, assign) BOOL      isOver;
@property (nonatomic, assign) BOOL      iskilometerPost;
@property (nonatomic, assign) CGFloat   distance;
@property (nonatomic, assign) CGFloat   correctDistance;
@property (nonatomic, assign) CGFloat   currentHeading;


@end

@implementation LJMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}
-(void)dealloc{
    [LJOptionPlistFile saveArray:self.locationsArray ToPlistFile:self.lastDate];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"updateMap" object:nil];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"showTrack" object:nil];
    [[NSNotificationCenter defaultCenter]removeHandlerObserverWithName:@"stop" object:nil];
}
-(void)initUI
{
    self.mainMapView=[[MAMapView alloc]initWithFrame:CGRectMake(0, 0, IPHONE_WIDTH, IPHONE_HEIGHT-20)];
    self.mainMapView.delegate=self;
    self.mainMapView.showsUserLocation=YES;
    self.mainMapView.distanceFilter=5;
    self.mainMapView.desiredAccuracy=kCLLocationAccuracyBestForNavigation;//导航级最佳精度
    self.mainMapView.headingFilter=1;//方向变化
    //self.mainMapView.openGLESDisabled=YES;
    
    // 追踪用户的location与heading更新 MAUserTrackingModeFollowWithHeading
    [self.mainMapView setUserTrackingMode:MAUserTrackingModeFollow animated:YES];
    self.mainMapView.customizeUserLocationAccuracyCircleRepresentation=YES;
    
    //后台继续定位：
    self.mainMapView.pausesLocationUpdatesAutomatically=NO;
    self.mainMapView.allowsBackgroundLocationUpdates=YES;
    [self.view addSubview:self.mainMapView];
    
    
    //设置指南针位置
    self.mainMapView.compassOrigin=CGPointMake(self.mainMapView.compassOrigin.x, 22);
    self.mainMapView.scaleOrigin=CGPointMake(self.mainMapView.scaleOrigin.x, 22);
    
    @weakify(self);
    UIButton* locationButton=[[UIButton alloc]initWithFrame:CGRectMake(12, IPHONE_HEIGHT-100, 40, 40)];
    locationButton.layer.cornerRadius=3;
    locationButton.backgroundColor=[UIColor whiteColor];
    [locationButton setImage:[[UIImage imageNamed:@"location_yes"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [locationButton setImage:[[UIImage imageNamed:@"location_no"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
    locationButton.imageView.tintColor=kSystemColor;
    [locationButton addTargetClickHandler:^(UIButton* sender, id status) {
        @strongify(self);
        if (sender.selected) {
            [self.mainMapView setMapStatus:[MAMapStatus statusWithCenterCoordinate:self.currentLocation zoomLevel:20 rotationDegree:0 cameraDegree:0.0f screenAnchor:CGPointMake(0.5, 0.5)] animated:YES];
        }else{
            [self.mainMapView setMapStatus:[MAMapStatus statusWithCenterCoordinate:self.currentLocation zoomLevel:20 rotationDegree:self.currentHeading cameraDegree:30.0f screenAnchor:CGPointMake(0.5, 0.5)] animated:YES];
        }
        sender.selected=!sender.selected;
    }];
    [self.view addSubview:locationButton];
    
    LJButton_Google* runButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    runButton.frame=CGRectMake(70, IPHONE_HEIGHT-100, IPHONE_WIDTH-140, 40);
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
    
    LJButton_Google* followButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    followButton.circleEffectColor=[UIColor whiteColor];
    followButton.frame=CGRectMake(IPHONE_WIDTH-43, 64, 40, 40);
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
        }
    }];
    self.followButton=followButton;
    [self.view addSubview:followButton];
    
    LJButton_Google* correctButton=[LJButton_Google buttonWithType:UIButtonTypeCustom];
    correctButton.circleEffectColor=[UIColor whiteColor];
    correctButton.frame=CGRectMake(IPHONE_WIDTH-43, 110, 40, 40);
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
    
    _showTrackAnnotaionView=[[UIButton alloc]initWithFrame:CGRectMake(IPHONE_WIDTH-50, IPHONE_HEIGHT-100, 40, 40)];
    _showTrackAnnotaionView.layer.cornerRadius=3;
    _showTrackAnnotaionView.backgroundColor=[UIColor whiteColor];
    [_showTrackAnnotaionView setImage:[[UIImage imageNamed:@"vip_menu_list_address"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_showTrackAnnotaionView setImage:[[UIImage imageNamed:@"vip_menu_list_address"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateSelected];
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.currentLocation.latitude>0.01) {
            [self.mainMapView setZoomLevel:15 animated:NO];
            [self.mainMapView setCenterCoordinate:self.currentLocation animated:YES];
        }
    });
}

-(void)initData{
    self.locationsArray=[NSMutableArray array];
    self.colorArray=[NSMutableArray array];
    self.colorIndexes=[NSMutableArray array];
    self.trackColorArray=[NSMutableArray array];
    self.speedArray=[NSMutableArray array];
    self.kiolmeterPostArray=[NSMutableArray array];
    
    [self.colorArray addObject:kRGBColor(0.0f, 60, 170, 0.8)];
    for (NSInteger i=1; i<=10; i++) {
        UIColor* lineColor=kRGBColor(255*i/10.0f, 60, 170, 0.8);
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

#pragma mark - ================ Delegate ==================
/**  位置更新，得到经纬度 */
-(void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    DLog(@"speed:%.2f, accuracyH:%.2f, accuracyV:%.2f", userLocation.location.speed, userLocation.location.horizontalAccuracy, userLocation.location.verticalAccuracy);
    
    if (updatingLocation) {
        if (self.isRun) {
            //过滤 相同经纬度的点
            if (self.currentLocation.latitude != userLocation.coordinate.latitude &&
                self.currentLocation.longitude != userLocation.coordinate.longitude) {
                //过滤 精度不高的点 和 没有速度或者速度过高的点。
                if (userLocation.location.speed >1 && userLocation.location.speed*3.6 <120 && userLocation.location.horizontalAccuracy<20 && userLocation.location.verticalAccuracy<20) {
                    [self saveLocation:userLocation.coordinate];
                    [self showTrackTime:self.lastDate isUpdate:YES];
                }
            }
            
        }else if(self.followButton.selected){
            [self.mainMapView setCenterCoordinate:userLocation.coordinate animated:YES];
        }
        DLog(@"latitude: %f, longitude: %f heading:%f %f %f \n%@", userLocation.coordinate.latitude, userLocation.coordinate.longitude, userLocation.heading.magneticHeading, userLocation.heading.trueHeading, userLocation.heading.headingAccuracy, userLocation.heading);
    }else{//head 只是设备的方向，地图旋转后 这个head方向并不会改变，只有设备旋转才会改变
        self.currentHeading=userLocation.heading.trueHeading;
        UIImage* image=[UIImage imageNamed:@"direction"];
        image=[LJImageTools rotationImage:image angle:self.currentHeading-mapView.rotationDegree clip:YES];
        _annotationView.image=image;
        
        DLog(@"heading: %f --%f -- %f", userLocation.heading.trueHeading, userLocation.heading.magneticHeading, userLocation.heading.headingAccuracy);
    }
    self.currentLocation=userLocation.coordinate;
}
/**  因为无法监听地图的方向rotationDegree 的值，所以就当做旋转地图时，或多或少会改变地图大小 */
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
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
        accuracyCircleRenderer.fillColor=[UIColor colorWithRed:0 green:1 blue:0 alpha:0.4];
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
        if (self.iskilometerPost && [pointAnnotation.subtitle isEqualToString:kilometerIndentifier]) {
            identifier = kilometerIndentifier;
        }
        
        MAPinAnnotationView* annotationView=(MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!annotationView) {
            annotationView=[[MAPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.canShowCallout=YES;  //设置气泡弹出，默认NO
            annotationView.animatesDrop=YES;    //动画效果，默认NO
            annotationView.pinColor=MAPinAnnotationColorPurple;
            annotationView.lj_size=CGSizeMake(30, 30);
            
            if (self.iskilometerPost && [identifier isEqualToString:kilometerIndentifier]) {
                annotationView.centerOffset = CGPointMake(0, -12.5);
                annotationView.pinColor=MAPinAnnotationColorRed;
                annotationView.enabled = NO;
            }
        }
        if (self.iskilometerPost && [identifier isEqualToString:kilometerIndentifier]) {
            
            [annotationView setLabelText:pointAnnotation.title font:[UIFont boldSystemFontOfSize:12] color:[UIColor greenColor]];
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
        [self saveLocation:self.currentLocation];
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
    //[self saveLocation:self.currentLocation];
}

-(void)stopRun{
    self.isRun=NO;
}

-(void)saveLocation:(CLLocationCoordinate2D)coordinate
{
    NSString* timestamp=[TimeTools getCurrentTimestamp];
    NSString* timeStr=[TimeTools getCurrentTimesType:@"yyyy-MM-dd"];
    if (![timeStr isEqualToString:self.tempCurrentDate]) {
        [LJOptionPlistFile saveObject:timeStr ToPlistFile:dateListName inHead:YES];
        self.lastDate=timeStr;
    }
    NSArray* tempLocation = @[timestamp, @(coordinate.latitude),@(coordinate.longitude)];
    [LJOptionPlistFile saveObject:tempLocation ToPlistFile:self.lastDate inHead:NO];
    [self.locationsArray addObject:tempLocation];
}

-(void)showTrackTime:(NSString*)timeStr isUpdate:(BOOL)update
{
    
    NSArray* array = nil;
    if (update) {
        self.correctDistance = 0;
        array = [NSArray arrayWithArray:self.locationsArray];
    }else{
        if (!timeStr) {
            array = [NSArray arrayWithArray:self.locationsArray];
        }else{
            self.correctDistance = 0;
            array = [LJOptionPlistFile readPlistFile:timeStr];
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
            CGFloat tempSpeed=time==0 || distance==0 ? 0 : distance/time;
            [self.speedArray addObject:@(tempSpeed)];
            
            //根据速度 计算颜色
            [self.trackColorArray addObject:self.colorArray[index]];
            [self.colorIndexes addObject:@(i)];
        }
    }
    
    self.title=[NSString stringWithFormat:@"总路程%.2f公里",self.distance/1000.0];
    if (self.correctDistance > 0.01) {
        self.title=[NSString stringWithFormat:@"总路程%.2f公里",self.correctDistance/1000.0];
    }
    
    //构造折线对象
    MAMultiPolyline* commonPolyline =[MAMultiPolyline polylineWithCoordinates:commonPolylineCoords count:array.count drawStyleIndexes:self.colorIndexes];
    
    [self.mainMapView addOverlay:commonPolyline];
    if(self.followButton.selected || !update){
        [self.mainMapView setCenterCoordinate:commonPolylineCoords[array.count-1] animated:YES];
    }
    if (self.isOver || !update) {
        [self showKilometerPostAnnotation];
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
        DLog(@"..%@", errorDesc);
        @strongify(self);
        self.correctButton.hidden = YES;
    }];
    
}

-(void)showKilometerPostAnnotation{
    self.iskilometerPost = YES;
    for (NSInteger i=0; i<self.kiolmeterPostArray.count; i++) {
        
        NSArray* location=self.kiolmeterPostArray[i];
        CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] floatValue], [location[2] floatValue]);
        MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
        
        pointAnnotation.coordinate = coordinate;
        pointAnnotation.title = [NSString stringWithFormat:@"%ld", i+1];
        pointAnnotation.subtitle = kilometerIndentifier;
        [self.mainMapView addAnnotation:pointAnnotation];
    }
}

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
                CLLocationCoordinate2D coordinate=CLLocationCoordinate2DMake([location[1] floatValue], [location[2] floatValue]);
                MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
                pointAnnotation.coordinate = coordinate;
                pointAnnotation.title = [TimeTools timestampChangesStandarTime:location[0]];
                pointAnnotation.subtitle=[NSString stringWithFormat:@"速度：%.2f公里/小时", [self.speedArray[i] floatValue]/1000*3600];
                [self.mainMapView addAnnotation:pointAnnotation];
            }
        }
        
    }else{
        for (id<MAAnnotation> view in self.mainMapView.annotations) {
            if (![view isKindOfClass:[MAUserLocation class]]) {
                [self.mainMapView removeAnnotation:view];
            }
        }
        [self showKilometerPostAnnotation];
    }
}

@end
