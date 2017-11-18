//
//  LJHistoryCell.m
//  LJTrack
//
//  Created by LiJie on 2017/11/18.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import "LJHistoryCell.h"

@implementation LJHistoryCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.renameTextField.delegate = self;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.renameTextField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if (self.endEditHandler) {
        self.endEditHandler();
    }
}




- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

@end
