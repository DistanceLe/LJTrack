//
//  XAxisView.h
//  WSLineChart
//
//  Created by iMac on 16/11/17.
//  Copyright © 2016年 zws. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XAxisView : UIView

@property (assign, nonatomic)CGFloat    pointGap;//点之间的距离
@property (nonatomic, assign)BOOL       showAnimation;//是否有动画
@property (nonatomic, strong)UIColor*   lineColor;

- (id)initWithFrame:(CGRect)frame xTitleArray:(NSArray*)xTitleArray yValueArray:(NSArray*)yValueArray yMax:(CGFloat)yMax yMin:(CGFloat)yMin;

@end
