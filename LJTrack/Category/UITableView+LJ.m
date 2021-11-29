//
//  UITableView+LJ.m
//  CoolMesh
//
//  Created by lijie on 2021/9/22.
//  Copyright © 2021 lijie. All rights reserved.
//

#import "UITableView+LJ.h"
#import <objc/runtime.h>

@implementation UITableView (LJ)

+ (void)load
{
    if (@available(iOS 15.0, *)) {
        //            table.sectionHeaderTopPadding = 0;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Method setText =class_getInstanceMethod([UITableView class], @selector(awakeFromNib));
            Method setTextMySelf =class_getInstanceMethod([UITableView class],@selector(awakeFromNibHooked));
            
            IMP setTextImp =method_getImplementation(setText);
            IMP setTextMySelfImp =method_getImplementation(setTextMySelf);
            
            BOOL didAddMethod = class_addMethod([UITableView class], @selector(awakeFromNib), setTextMySelfImp, method_getTypeEncoding(setTextMySelf));
            
            if (didAddMethod) {
                class_replaceMethod([UITableView class], @selector(awakeFromNibHooked), setTextImp, method_getTypeEncoding(setText));
            }else{
                method_exchangeImplementations(setText, setTextMySelf);
            }
            
            
            //设置字体
//            setText =class_getInstanceMethod([UITableView class], @selector(sectionHeaderTopPadding));
//            setTextMySelf =class_getInstanceMethod([UITableView class],@selector(sectionHeaderTopPaddingHooked));
//
//            setTextImp =method_getImplementation(setText);
//            setTextMySelfImp =method_getImplementation(setTextMySelf);
//
//            didAddMethod = class_addMethod([UITableView class], @selector(sectionHeaderTopPadding), setTextMySelfImp, method_getTypeEncoding(setTextMySelf));
//
//            if (didAddMethod) {
//                class_replaceMethod([UITableView class], @selector(sectionHeaderTopPaddingHooked), setTextImp, method_getTypeEncoding(setText));
//            }else{
//                method_exchangeImplementations(setText, setTextMySelf);
//            }
        });
    }
}
//-(void)awakeFromNib{
//
//}
//-(void)setSectionHeaderTopPaddingHooked:(CGFloat)sectionHeaderTopPadding{
//    if (@available(iOS 15.0, *)) {
//        [self setSectionHeaderTopPaddingHooked:0];
//    } else {
//        // Fallback on earlier versions
//    }
//}
-(void)awakeFromNibHooked{
    if (@available(iOS 15.0, *)) {
        self.sectionHeaderTopPadding = 0;
    }
    [super awakeFromNib];
}

@end
