//
//  NSNotificationCenter+LJ.h
//  LJTrack
//
//  Created by LiJie on 16/6/15.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (LJ)

-(void)addObserverName:(NSString*)name object:(id)obj handler:(StatusBlock)handler;

-(void)removeHandlerObserverWithName:(NSString *)name object:(id)obj;

@end
