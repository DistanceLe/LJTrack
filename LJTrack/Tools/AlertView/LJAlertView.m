//
//  LJAlertView.m
//  LJTrack
//
//  Created by LiJie on 2016/10/11.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import "LJAlertView.h"
#import <objc/runtime.h>

@interface LJAlertView ()

@property(nonatomic, strong)UIAlertController* tempAlert;
@property(nonatomic, strong)CommitBlock tempBlock;
@property(nonatomic, strong)NSString* cancelTitle;
@property(nonatomic, strong)NSArray* titleArray;

@end

@implementation LJAlertView
{
    __weak UIViewController* tempVC;
}

+(void)showAlertTitle:(NSString *)title
              message:(NSString *)message
       showController:(UIViewController *)showController
          cancelTitle:(NSString *)cancelTitle
          otherTitles:(NSArray *)otherTitles
          clickButton:(CommitBlock)commit{
    if (!showController || ![showController isKindOfClass:[UIViewController class]]) {
        return;
    }
    LJAlertView* tempSelf=[[LJAlertView alloc]initWithTitle:title
                                                    message:message
                                             showController:showController
                                                cancelTitle:cancelTitle
                                                otherTitles:otherTitles
                                                clickButton:commit];
    [tempSelf initUI];
}

-(instancetype)initWithTitle:(NSString*)title
                     message:(NSString *)message
              showController:(UIViewController *)showController
                 cancelTitle:(NSString *)cancelTitle
                 otherTitles:(NSArray *)otherTitles
                 clickButton:(CommitBlock)commit{
    
    self = [super init];
    if (self) {
        self.tempBlock=commit;
        self.cancelTitle=cancelTitle;
        self.titleArray=otherTitles;
        self.tempAlert=[UIAlertController alertControllerWithTitle:title
                                                           message:message
                                                    preferredStyle:UIAlertControllerStyleAlert];
        tempVC=showController;
    }
    return self;
}

static char alertKey;
-(void)initUI{
    objc_setAssociatedObject(AppDelegateInstance, &alertKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (IFISNULL(self.cancelTitle)) {
        self.cancelTitle=@"取消";
    }
    if (self.titleArray.count<1) {
        self.titleArray=@[@"确定"];
    }
    
    @weakify(self);
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:self.cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        @strongify(self);
        if (self.tempBlock){
            self.tempBlock(0);
            objc_setAssociatedObject(AppDelegateInstance, &alertKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }];
    [_tempAlert addAction:cancelAction];
    
    for (NSInteger i=1; i<=self.titleArray.count; i++) {
        
        UIAlertAction* otherAction=[UIAlertAction actionWithTitle:self.titleArray[i-1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            @strongify(self);
            if (self.tempBlock){
                self.tempBlock(i);
                objc_setAssociatedObject(AppDelegateInstance, &alertKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }];
        [_tempAlert addAction:otherAction];
    }
    [tempVC presentViewController:self.tempAlert animated:YES completion:nil];
}

-(void)dealloc{
    DLog(@"LJAlert dealloc");
}



@end
