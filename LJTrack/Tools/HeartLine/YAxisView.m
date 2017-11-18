//
//  YAxisView.m
//  WSLineChart
//
//  Created by iMac on 16/11/17.
//  Copyright © 2016年 zws. All rights reserved.
//

#import "YAxisView.h"

#define xAxisTextGap 5 //x轴文字与坐标轴间隙
#define numberOfYAxisElements 5 // y轴分为几段

#define topMargin 30   // 为顶部留出的空白

#define kChartLineColor         [[UIColor whiteColor]colorWithAlphaComponent:0.2]
#define kChartTextColor         [[UIColor whiteColor]colorWithAlphaComponent:0.8]
#define YAxisBackColor          [UIColor clearColor]


@interface YAxisView ()

@property (assign, nonatomic) CGFloat yMax;
@property (assign, nonatomic) CGFloat yMin;

@end

@implementation YAxisView

- (id)initWithFrame:(CGRect)frame yMax:(CGFloat)yMax yMin:(CGFloat)yMin {
    
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = YAxisBackColor;
        self.yMax = yMax;
        self.yMin = yMin;
        
    }
    return self;
}



- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 计算坐标轴的位置以及大小
    NSDictionary *attr = @{NSFontAttributeName : [UIFont systemFontOfSize:8]};
    
    CGSize XlabelSize = [@"x\nx" sizeWithAttributes:attr];
    
    [self drawLine:context startPoint:CGPointMake(self.frame.size.width-1, 0) endPoint:CGPointMake(self.frame.size.width-1, self.frame.size.height - XlabelSize.height - xAxisTextGap) lineColor:kChartLineColor lineWidth:1];
    
    
    NSDictionary *waterAttr = @{NSFontAttributeName : [UIFont systemFontOfSize:8]};
    
    //Y轴的单位
    if (self.showUnit && self.unitStr.length>0) {
        CGSize waterLabelSize = [self.unitStr sizeWithAttributes:waterAttr];
        CGRect waterRect = CGRectMake(self.frame.size.width -2 - waterLabelSize.width, 5,waterLabelSize.width,waterLabelSize.height);
        [self.unitStr drawInRect:waterRect withAttributes:@{NSFontAttributeName :[UIFont systemFontOfSize:7],NSForegroundColorAttributeName:kChartTextColor}];
    }
    

    // Label做占据的高度
//    CGSize labelSize = [@"x" sizeWithAttributes:attr];
//    CGFloat allLabelHeight = self.frame.size.height - xAxisTextGap - XlabelSize.height;
    // Label之间的间隙
//    CGFloat labelMargin = (allLabelHeight + XlabelSize.height - (numberOfYAxisElements + 1) * labelSize.height) / numberOfYAxisElements;

    CGFloat labelMargin = (self.frame.size.height - topMargin - XlabelSize.height - 5 ) / 5;
//    CGFloat labelMargin = (allLabelHeight - topMargin - XlabelSize.height  - 5 * 1) / 5;
    
    // 添加Label
    for (int i = 0; i < numberOfYAxisElements + 1; i++) {

        CGFloat avgValue = (self.yMax - self.yMin) / numberOfYAxisElements;
        
        // 判断是不是小数
        if ([self isPureFloat:self.yMin + avgValue * i]) {
            CGSize yLabelSize = [[NSString stringWithFormat:@"%.0f", self.yMin + avgValue * i] sizeWithAttributes:waterAttr];

            [[NSString stringWithFormat:@"%.0f", self.yMin + avgValue * i]
             drawInRect:CGRectMake(self.frame.size.width - 1-5 - yLabelSize.width,
                                   self.frame.size.height - XlabelSize.height - 5 - labelMargin* i - yLabelSize.height/2,
                                   yLabelSize.width,
                                   yLabelSize.height)
             withAttributes:@{NSFontAttributeName :[UIFont systemFontOfSize:8],
                              NSForegroundColorAttributeName:kChartTextColor}];
        }
        else {
            CGSize yLabelSize = [[NSString stringWithFormat:@"%.0f", self.yMin + avgValue * i] sizeWithAttributes:waterAttr];

            [[NSString stringWithFormat:@"%.0f", self.yMin + avgValue * i]
             drawInRect:CGRectMake(self.frame.size.width - 1-5 - yLabelSize.width,
                                   self.frame.size.height - XlabelSize.height - 5 - labelMargin* i - yLabelSize.height/2,
                                   yLabelSize.width,
                                   yLabelSize.height)
             withAttributes:@{NSFontAttributeName :[UIFont systemFontOfSize:8],
                              NSForegroundColorAttributeName:kChartTextColor}];
        }
        
    }
}

// 判断是小数还是整数
- (BOOL)isPureFloat:(CGFloat)num
{
    int i = num;
    
    CGFloat result = num - i;
    
    // 当不等于0时，是小数
    return result != 0;
}

- (void)drawLine:(CGContextRef)context startPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint lineColor:(UIColor *)lineColor lineWidth:(CGFloat)width {
    
    CGContextSetShouldAntialias(context, YES ); //抗锯齿
    CGColorSpaceRef Linecolorspace1 = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(context, Linecolorspace1);
    CGContextSetLineWidth(context, width);
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    CGContextStrokePath(context);
    CGColorSpaceRelease(Linecolorspace1);
}



@end
