//
//  WSLineChartView.h
//  WSLineChart
//
//  Created by iMac on 16/11/17.
//  Copyright © 2016年 zws. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WSLineChartView : UIView


@property(nonatomic, strong)UIColor* lineColor;

/**  是否显示无数据时的图片 默认不显示NO */
@property(nonatomic, assign)BOOL showEmptyImageView;
/**  无数据时的图片 */
@property(nonatomic, strong)UIImage* emptyBackImage;
@property(nonatomic, strong)UIColor* emptyLabelColor;


-(void)setxTitleArray:(NSArray<NSString*>*)xTitleArray
          yValueArray:(NSArray<NSString*>*)yValueArray
                 yMax:(CGFloat)yMax
                 yMin:(CGFloat)yMin
                xUnit:(NSString*)XUnit
                yUnit:(NSString*)yUnit
            animation:(BOOL)animation;



@end
