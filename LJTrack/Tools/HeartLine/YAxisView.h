//
//  YAxisView.h
//  WSLineChart
//
//  Created by iMac on 16/11/17.
//  Copyright © 2016年 zws. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAxisView : UIView

@property(nonatomic, assign)BOOL showUnit;
@property(nonatomic, strong)NSString* unitStr;

- (id)initWithFrame:(CGRect)frame yMax:(CGFloat)yMax yMin:(CGFloat)yMin;



@end
