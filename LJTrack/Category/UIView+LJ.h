//
//  UIView+LJ.h
//  LJTrack
//
//  Created by LiJie on 16/6/17.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIView (LJ)


@property (nonatomic, assign)CGFloat lj_height;
@property (nonatomic, assign)CGFloat lj_width;
@property (nonatomic, assign)CGFloat lj_y;
@property (nonatomic, assign)CGFloat lj_x;

@property(nonatomic, assign) CGPoint lj_origin;
@property(nonatomic, assign) CGSize  lj_size;

-(void)addTapGestureHandler:(StatusBlock)handler;



@end
