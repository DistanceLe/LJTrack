//
//  LJHistoryViewController.m
//  LJTrack
//
//  Created by LiJie on 16/6/15.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import "LJHistoryViewController.h"
#import "LJHistoryCell.h"

#import "LJOptionPlistFile.h"
#import "TimeTools.h"
#import "LJAlertView.h"
#import "ProgressHUD.h"

@interface LJHistoryViewController ()

@property(nonatomic, strong)NSMutableArray* dataArray;
@property(nonatomic, strong)NSMutableArray* customNamesArray;
@property(nonatomic, strong)NSMutableArray* coordinateArray;

@property(nonatomic, assign)NSInteger       showIndex;
@property(nonatomic, assign)BOOL            renameEdit;

@end

@implementation LJHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)initData{
    //[LJOptionPlistFile deleteAllObjectInPlistFile:customName];
    @weakify(self);
    [[NSNotificationCenter defaultCenter]addObserverName:@"canShow" object:nil handler:^(NSNotification* sender, id status) {
        @strongify(self);
        if ([sender.object boolValue]) {
            
            [LJAlertView showAlertTitle:@"正在运动中" message:@"是否要停止运动" showController:self cancelTitle:@"不要" otherTitles:@[@"停止运动"] clickButton:^(NSInteger flag) {
                if (flag==1) {
                    [self showTrack];
                }
            }];
            
        }else{
            [self showTrack];
        }
    }];
    self.coordinateArray=[NSMutableArray array];
    self.tableView.mj_header=[MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self);
        [self.tableView.mj_header endRefreshing];
        [self initCoordinateData];
    }];
    
    [ProgressHUD show:@"加载中" autoStop:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
    
        self.dataArray=[NSMutableArray arrayWithArray:[LJOptionPlistFile readPlistFile:dateListName]];
        NSArray* nameArray = [LJOptionPlistFile readPlistFile:customName];
        self.customNamesArray=[NSMutableArray arrayWithArray:nameArray];
        NSInteger num = self.dataArray.count-self.customNamesArray.count;
        for (NSInteger i = 0; i < num; i++) {
            [self.customNamesArray insertObject:@"" atIndex:0];
        }
        
        for (NSString* timeStr in self.dataArray) {
            NSArray* array=[LJOptionPlistFile readPlistFile:timeStr];
            if (array==nil) {
                array=@[];
            }
            [self.coordinateArray addObject:array];
        }
        [ProgressHUD dismiss];
        [self.tableView reloadData];
    });
}

-(void)initCoordinateData{
    NSArray* tempArray=[LJOptionPlistFile readPlistFile:dateListName];
    NSArray* array=[LJOptionPlistFile readPlistFile:tempArray[0]];
    if (array==nil) {
        array=@[];
    }
    if (tempArray.count==self.dataArray.count) {
        [self.coordinateArray replaceObjectAtIndex:0 withObject:array];
    }else{
        for (NSInteger i = tempArray.count-self.dataArray.count-1; i > 0; i++) {
            NSArray* subArray=[LJOptionPlistFile readPlistFile:tempArray[i]];
            if (subArray==nil) {
                subArray=@[];
            }
            [self.coordinateArray insertObject:array atIndex:0];
        }
        [self.coordinateArray insertObject:array atIndex:0];
    }
    self.dataArray=[NSMutableArray arrayWithArray:tempArray];
    
    NSArray* nameArray = [LJOptionPlistFile readPlistFile:customName];
    self.customNamesArray=[NSMutableArray arrayWithArray:nameArray];
    NSInteger num = self.dataArray.count-self.customNamesArray.count;
    for (NSInteger i = 0; i < num; i++) {
        [self.customNamesArray insertObject:@"" atIndex:0];
    }
    
    [self.tableView reloadData];
}


-(void)initUI{
    self.tableView.rowHeight=60;
}

-(void)showTrack{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @weakify(self);
        [LJAlertView showAlertTitle:@"是否叠加显示" message:nil showController:self cancelTitle:@"取消" otherTitles:@[@"单独显示",@"叠加显示"] clickButton:^(NSInteger flag) {
            @strongify(self);
            if (flag==2) {
                [[NSNotificationCenter defaultCenter]postNotificationName:@"showTrackAbove" object:self.dataArray[self.showIndex]];
                [self.tabBarController setSelectedIndex:0];
            }else if(flag == 1){
                [[NSNotificationCenter defaultCenter]postNotificationName:@"showTrack" object:self.dataArray[self.showIndex]];
                [self.tabBarController setSelectedIndex:0];
            }else{
                
            }
        }];
    });
}
- (IBAction)renameClick:(UIBarButtonItem *)sender {
    
    self.renameEdit = !self.renameEdit;
    if (self.renameEdit) {
        sender.title = @"完成";
    }else{
        sender.title = @"改名";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            BOOL save =  [LJOptionPlistFile saveArray:self.customNamesArray ToPlistFile:customName];
            if (!save) {
                [ProgressHUD show:@"保存失败!"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [ProgressHUD dismiss];
                });
            }
        });
    }
    [self.tableView reloadData];
}

#pragma mark - ================ Delegate ==================
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LJHistoryCell* cell=[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    NSArray* array=self.coordinateArray[indexPath.row];
    
    NSString* dateStr=self.dataArray[indexPath.row];
    dateStr=[dateStr stringByAppendingString:@" \t\t"];
    
    if (array.count<1) {
        cell.headTitleLabel.text=[NSString stringWithFormat:@"%@耗时 00:00:00", dateStr];
        cell.headDetailLabel.text=nil;
        cell.customLabel.text = @"";
    }else{
        NSString* startTime=[TimeTools timestampChangesStandarTime:array[array.count-1][0] Type:@"HH:mm:ss"];
        NSString* endTime=[TimeTools timestampChangesStandarTime:array[0][0] Type:@"HH:mm:ss"];
        NSString* componentTimeStr=[NSString stringWithFormat:@"%@~%@", startTime, endTime];
        componentTimeStr=[componentTimeStr stringByAppendingString:@"\t\t"];
        
        long intervalStart=(long)[array[0][0] longLongValue];
        long intervalEnd=(long)[array[array.count-1][0] longLongValue];
        
        long intervalTime=labs(intervalStart-intervalEnd);
        NSString* time=[TimeTools timestampChangesStandarTime:[NSString stringWithFormat:@"%ld",intervalTime] Type:@"HH:mm:ss"];
        cell.headTitleLabel.text=[NSString stringWithFormat:@"%@耗时 %@", dateStr, time];
        cell.headDetailLabel.text=[NSString stringWithFormat:@"%@共有%ld个定位点", componentTimeStr, (unsigned long)array.count];
        cell.customLabel.text = self.customNamesArray[indexPath.row];
        
        if (self.renameEdit) {
            cell.customLabel.hidden = YES;
            cell.renameTextField.hidden = NO;
            cell.renameTextField.text = cell.customLabel.text;
            @weakify(cell);
            [cell setEndEditHandler:^{
                DLog(@"end edit");
                @strongify(cell);
                [self.customNamesArray replaceObjectAtIndex:indexPath.row withObject:cell.renameTextField.text];
                cell.customLabel.text = cell.renameTextField.text;
            }];
        }else{
            cell.customLabel.hidden = NO;
            cell.renameTextField.hidden = YES;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.renameEdit) {
        
        LJHistoryCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        [cell.renameTextField becomeFirstResponder];
        return;
    }
    
    if ([self.coordinateArray[indexPath.row] count]<1) {
        return;
    }
    self.showIndex=indexPath.row;
    [[NSNotificationCenter defaultCenter]postNotificationName:@"showTrack" object:@"canShow"];
}

-(NSArray<UITableViewRowAction*>*)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    @weakify(self);
    UITableViewRowAction* deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        @strongify(self);
        [LJAlertView showAlertTitle:@"删除路径" message:@"" showController:self cancelTitle:@"取消" otherTitles:@[@"删除"] clickButton:^(NSInteger flag) {
            if (flag == 1) {
                [LJOptionPlistFile deleteAllObjectInPlistFile:self.dataArray[indexPath.row]];
                [LJOptionPlistFile deleteObject:self.dataArray[indexPath.row] InPlistFile:dateListName];
                [self.dataArray removeObjectAtIndex:indexPath.row];
                [self.coordinateArray removeObjectAtIndex:indexPath.row];
                [self.customNamesArray removeObjectAtIndex:indexPath.row];
                [LJOptionPlistFile saveArray:self.customNamesArray ToPlistFile:customName];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
            }
        }];
    }];

    return @[deleteAction];
}


@end
