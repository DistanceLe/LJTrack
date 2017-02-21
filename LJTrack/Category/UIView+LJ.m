//
//  UIView+LJ.m
//  LJTrack
//
//  Created by LiJie on 16/6/17.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import "UIView+LJ.h"
#import <objc/runtime.h>

@interface UIView ()

@property(nonatomic, strong)StatusBlock tempViewBlock;

@end

@implementation UIView (LJ)

- (CGFloat)lj_height
{
    return self.frame.size.height;
}

- (void)setLj_height:(CGFloat)lj_height
{
    CGRect temp = self.frame;
    temp.size.height = lj_height;
    self.frame = temp;
}

- (CGFloat)lj_width
{
    return self.frame.size.width;
}

- (void)setLj_width:(CGFloat)lj_width
{
    CGRect temp = self.frame;
    temp.size.width = lj_width;
    self.frame = temp;
}


- (CGFloat)lj_y
{
    return self.frame.origin.y;
}

- (void)setLj_y:(CGFloat)lj_y
{
    CGRect temp = self.frame;
    temp.origin.y = lj_y;
    self.frame = temp;
}

- (CGFloat)lj_x
{
    return self.frame.origin.x;
}

- (void)setLj_x:(CGFloat)lj_x
{
    CGRect temp = self.frame;
    temp.origin.x = lj_x;
    self.frame = temp;
}

//=====================================
-(void)setLj_origin:(CGPoint)lj_origin
{
    CGRect frame=self.frame;
    frame.origin=lj_origin;
    self.frame=frame;
}
-(CGPoint)lj_origin
{
    return self.frame.origin;
}

-(void)setLj_size:(CGSize)lj_size
{
    CGRect frame=self.frame;
    frame.size=lj_size;
    self.frame=frame;
}
-(CGSize)lj_size
{
    return self.frame.size;
}

static char tempViewBlockKey;
-(void)setTempViewBlock:(StatusBlock)tempViewBlock
{
    objc_setAssociatedObject(self, &tempViewBlockKey, tempViewBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(StatusBlock)tempViewBlock
{
    return objc_getAssociatedObject(self, &tempViewBlockKey);
}

-(void)addTapGestureHandler:(StatusBlock)handler
{
    self.tempViewBlock=handler;
    UITapGestureRecognizer* tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handlerTapAction:)];
    [self addGestureRecognizer:tap];
}

-(void)handlerTapAction:(UITapGestureRecognizer*)tap
{
    self.tempViewBlock(tap, self);
}

@end
