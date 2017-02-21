//
//  LJAlertView.h
//  LJTrack
//
//  Created by LiJie on 2016/10/11.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CommitBlock)(NSInteger flag);

@interface LJAlertView : NSObject

/**  取消flag=0， 其他从1开始类推 */
+(void)showAlertTitle:(NSString*)title
              message:(NSString *)message
       showController:(UIViewController*)showController
          cancelTitle:(NSString *)cancelTitle
          otherTitles:(NSArray *)otherTitles
          clickButton:(CommitBlock)commit;
@end
