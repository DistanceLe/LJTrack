
//
//  WSLineChartView.m
//  WSLineChart
//
//  Created by iMac on 16/11/17.
//  Copyright © 2016年 zws. All rights reserved.
//

#import "WSLineChartView.h"
#import "XAxisView.h"
#import "YAxisView.h"

#define leftMargin 30
//#define defaultSpace 5
#define lastSpace 23



@interface WSLineChartView ()

@property(nonatomic, strong)UIImageView* emptyImageView;
@property(nonatomic, strong)UILabel*     emptyLabel;

@property (strong, nonatomic) NSArray *xTitleArray;
@property (strong, nonatomic) NSArray *yValueArray;
@property (assign, nonatomic) CGFloat yMax;
@property (assign, nonatomic) CGFloat yMin;
@property (strong, nonatomic) YAxisView *yAxisView;
@property (strong, nonatomic) XAxisView *xAxisView;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) CGFloat pointGap;
@property (assign, nonatomic) CGFloat defaultSpace;//间距

@property (assign, nonatomic) CGFloat moveDistance;

@property(nonatomic, assign)BOOL showAnimation;
@property(nonatomic, assign)BOOL canZoom;

@end

@implementation WSLineChartView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.lineColor = [UIColor redColor];
    }
    return self;
}

//-(void)didMoveToSuperview{
//    self.emptyImageView = [[UIImageView alloc]initWithFrame:self.superview.bounds];
//    self.emptyImageView.hidden = YES;
//    self.emptyImageView.userInteractionEnabled = YES;
//    [self.superview addSubview:self.emptyImageView];
//
//    self.emptyLabel = [[UILabel alloc]init];
//    self.emptyLabel.textColor = _emptyLabelColor;
//    self.emptyLabel.font = [UIFont systemFontOfSize:15];
//    self.emptyLabel.text = LS(@"CE_EmptyHeartInfo");
//    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
//    [self.emptyImageView addSubview:self.emptyLabel];
//}

-(void)setxTitleArray:(NSArray *)xTitleArray
          yValueArray:(NSArray *)yValueArray
                 yMax:(CGFloat)yMax
                 yMin:(CGFloat)yMin
                xUnit:(NSString*)XUnit
                yUnit:(NSString*)yUnit
            animation:(BOOL)animation{
    
    self.emptyImageView.frame = CGRectMake(-5, -5, self.superview.lj_width+10, self.superview.lj_height+10);
    self.emptyLabel.frame = CGRectMake(0, self.emptyImageView.lj_height-50, self.emptyImageView.lj_width, 40);
    if (self.showEmptyImageView && xTitleArray.count==0) {
        self.emptyImageView.hidden = NO;
        self.emptyImageView.image = self.emptyBackImage;
    }else{
        self.emptyImageView.hidden = YES;
    }
    
    self.xTitleArray = xTitleArray;
    self.yValueArray = yValueArray;
    self.yMax = yMax;
    self.yMin = yMin;
    self.showAnimation = animation;
    
    _defaultSpace = 23;
    self.pointGap = _defaultSpace;
    
    [self creatYAxisView:yUnit];
    [self creatXAxisView:yUnit Xunit:XUnit];
    
    
    //长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(event_longPressAction:)];
    longPress.minimumPressDuration = 0.1;
    [self.xAxisView addGestureRecognizer:longPress];
}

- (void)creatYAxisView:(NSString*)YUnit {
    if (self.yAxisView) {
        for (UIGestureRecognizer* gesture in self.yAxisView.gestureRecognizers) {
            [self.yAxisView removeGestureRecognizer:gesture];
        }
        [self.yAxisView removeFromSuperview];
    }
    self.yAxisView = [[YAxisView alloc]initWithFrame:CGRectMake(0, 0, leftMargin, self.frame.size.height) yMax:self.yMax yMin:self.yMin];
    self.yAxisView.unitStr = YUnit;
    self.yAxisView.showUnit = YES;
    [self addSubview:self.yAxisView];
}

- (void)creatXAxisView:(NSString*)YUnit Xunit:(NSString*)XUnit {
    if (self.xAxisView) {
        for (UIGestureRecognizer* gesture in self.xAxisView.gestureRecognizers) {
            [self.xAxisView removeGestureRecognizer:gesture];
        }
        [self.xAxisView removeFromSuperview];
    }else{
        _scrollView = [[UIScrollView alloc]initWithFrame:CGRectMake(leftMargin, 0, self.frame.size.width-leftMargin, self.frame.size.height)];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.bounces = NO;
        [self addSubview:_scrollView];
    }
    CGFloat width = self.xTitleArray.count * self.pointGap + lastSpace;
    if (width < (self.lj_width-30)) {
        self.canZoom = NO;
        width = (self.lj_width-30);
    }else{
        self.canZoom = YES;
    }
    self.xAxisView = [[XAxisView alloc] initWithFrame:CGRectMake(0, 0, width, self.frame.size.height) xTitleArray:self.xTitleArray yValueArray:self.yValueArray yMax:self.yMax yMin:self.yMin];
    self.xAxisView.XunitStr = XUnit;
    self.xAxisView.YunitStr = YUnit;
    self.xAxisView.isShowLabel = NO;
    self.xAxisView.lineColor = self.lineColor;
    self.xAxisView.showAnimation = self.showAnimation;
    if (self.canZoom) {
        // 2. 捏合手势
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        [self.xAxisView addGestureRecognizer:pinch];
    }
    
    [_scrollView addSubview:self.xAxisView];
    
    _scrollView.contentSize = self.xAxisView.frame.size;
    if (!self.showAnimation) {
        _scrollView.contentOffset = CGPointMake(_scrollView.contentSize.width - _scrollView.lj_width, 0);
    }
}

// 捏合手势监听方法
- (void)pinchGesture:(UIPinchGestureRecognizer *)recognizer
{
    if (!self.canZoom) {
        return;
    }
    if (recognizer.state == 3) {
        
        if (self.xAxisView.frame.size.width-lastSpace <= self.scrollView.frame.size.width) { //当缩小到小于屏幕宽时，松开回复屏幕宽度
            
            CGFloat scale = self.scrollView.frame.size.width / (self.xAxisView.frame.size.width-lastSpace);
            
            self.pointGap *= scale;
            
            [UIView animateWithDuration:0.25 animations:^{
                
                CGRect frame = self.xAxisView.frame;
                frame.size.width = self.scrollView.frame.size.width+lastSpace;
                self.xAxisView.frame = frame;
            }];
            
            self.xAxisView.pointGap = self.pointGap;
            
        }else if (self.xAxisView.frame.size.width-lastSpace >= self.xTitleArray.count * _defaultSpace){
            
            [UIView animateWithDuration:0.25 animations:^{
                CGRect frame = self.xAxisView.frame;
                frame.size.width = self.xTitleArray.count * _defaultSpace + lastSpace;
                self.xAxisView.frame = frame;
                
            }];
            
            self.pointGap = _defaultSpace;
            
            self.xAxisView.pointGap = self.pointGap;
        }
    }else{
        
        CGFloat currentIndex,leftMagin;
        if( recognizer.numberOfTouches == 2 ) {
            //2.获取捏合中心点 -> 捏合中心点距离scrollviewcontent左侧的距离
            CGPoint p1 = [recognizer locationOfTouch:0 inView:self.xAxisView];
            CGPoint p2 = [recognizer locationOfTouch:1 inView:self.xAxisView];
            CGFloat centerX = (p1.x+p2.x)/2;
            leftMagin = centerX - self.scrollView.contentOffset.x;
            //            NSLog(@"centerX = %f",centerX);
            //            NSLog(@"self.scrollView.contentOffset.x = %f",self.scrollView.contentOffset.x);
            //            NSLog(@"leftMagin = %f",leftMagin);
            
            
            currentIndex = centerX / self.pointGap;
            //            NSLog(@"currentIndex = %f",currentIndex);
            
            
            
            self.pointGap *= recognizer.scale;
            self.pointGap = self.pointGap > _defaultSpace ? _defaultSpace : self.pointGap;
            if (self.pointGap == _defaultSpace) {
                
                DLog(@"...已经放大到 最大了");
            }
            self.xAxisView.pointGap = self.pointGap;
            recognizer.scale = 1.0;
            
            self.xAxisView.frame = CGRectMake(0, 0, self.xTitleArray.count * self.pointGap + lastSpace, self.frame.size.height);
            
            self.scrollView.contentOffset = CGPointMake(currentIndex*self.pointGap-leftMagin, 0);
            //            NSLog(@"contentOffset = %f",self.scrollView.contentOffset.x);
            
        }
    }
    self.scrollView.contentSize = CGSizeMake(self.xAxisView.frame.size.width, 0);
}


- (void)event_longPressAction:(UILongPressGestureRecognizer *)longPress {
    
    if(UIGestureRecognizerStateChanged == longPress.state || UIGestureRecognizerStateBegan == longPress.state) {
        
        CGPoint location = [longPress locationInView:self.xAxisView];
        
        //相对于屏幕的位置
        CGPoint screenLoc = CGPointMake(location.x - self.scrollView.contentOffset.x, location.y);
        [self.xAxisView setScreenLoc:screenLoc];
        
        if (ABS(location.x - _moveDistance) > self.pointGap) { //不能长按移动一点点就重新绘图  要让定位的点改变了再重新绘图
            
            [self.xAxisView setIsShowLabel:YES];
            [self.xAxisView setIsLongPress:YES];
            self.xAxisView.currentLoc = location;
            _moveDistance = location.x;
        }
    }
    
    if(longPress.state == UIGestureRecognizerStateEnded)
    {
        _moveDistance = 0;
        //恢复scrollView的滑动
        [self.xAxisView setIsLongPress:NO];
        [self.xAxisView setIsShowLabel:NO];
        
    }
    
}



@end
