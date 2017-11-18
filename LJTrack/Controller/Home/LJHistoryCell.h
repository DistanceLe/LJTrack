//
//  LJHistoryCell.h
//  LJTrack
//
//  Created by LiJie on 2017/11/18.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LJHistoryCell : UITableViewCell<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *headTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *headDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *customLabel;
@property (weak, nonatomic) IBOutlet UITextField *renameTextField;

@property (nonatomic, strong)void(^endEditHandler)(void);

@end
