//
//  UIButton+LJ.h
//  LJTrack
//
//  Created by LiJie on 16/6/14.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ButtonHandler)(UIButton* but, id obj);

@interface UIButton (LJ)

-(void)addTargetClickHandler:(ButtonHandler)handler;

@end
