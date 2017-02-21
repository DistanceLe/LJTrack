//
//  MAAnnotationView+LJ.m
//  LJTrack
//
//  Created by LiJie on 2017/2/3.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import "MAAnnotationView+LJ.h"
#import <objc/runtime.h>

@interface MAAnnotationView ()

@property(nonatomic, strong)UILabel* contentLabel;

@end

@implementation MAAnnotationView (LJ)

static char labelKey;
-(void)setContentLabel:(UILabel *)contentLabel{
    objc_setAssociatedObject(self, &labelKey, contentLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UILabel *)contentLabel{
    return objc_getAssociatedObject(self, &labelKey);
}


-(void)setLabelText:(NSString *)text font:(UIFont *)font color:(UIColor *)color{
    if (!self.contentLabel) {
        self.contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.lj_width, self.lj_height-5)];
        self.contentLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.contentLabel];
    }
    self.contentLabel.textColor = color;
    self.contentLabel.font = font;
    self.contentLabel.text = text;
}






@end
