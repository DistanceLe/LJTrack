//
//  LJOfflineMapViewController.m
//  LJTrack
//
//  Created by LiJie on 16/6/14.
//  Copyright © 2016年 LiJie. All rights reserved.
//

#import "LJOfflineMapViewController.h"
#import "LJOfflineHeadView.h"
#import "OfflineTableViewCell.h"
#import <MAMapKit/MAMapKit.h>

@interface LJOfflineMapViewController ()

@property(nonatomic, strong)NSMutableArray* provincesArray;
@property(nonatomic, strong)NSArray*        municipaliteArray;

@property(nonatomic, strong)NSIndexPath* downloadIndexPath;
@property(nonatomic, assign)NSInteger editSection;
@property(nonatomic, assign)BOOL      showCity;

@end

@implementation LJOfflineMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"LJOfflineHeadView" bundle:nil] forHeaderFooterViewReuseIdentifier:headIdentify];
    self.tableView.separatorInset=UIEdgeInsetsZero;
    self.tableView.layoutMargins=UIEdgeInsetsZero;
    self.editSection=-1;
}

-(void)initData
{
    self.provincesArray=[NSMutableArray arrayWithArray:[MAOfflineMap sharedOfflineMap].provinces];
    self.municipaliteArray=[MAOfflineMap sharedOfflineMap].municipalities;
    [self.provincesArray insertObject:@[] atIndex:0];

    [self.tableView reloadData];
}

- (IBAction)rightClick:(UIBarButtonItem *)sender {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark - ================ Delegate ==================
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.provincesArray.count;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.showCity && section == self.editSection) {
        if (section==0) {
            return [self.municipaliteArray count];
        }
        MAOfflineProvince* province=self.provincesArray[section];
        return province.cities.count;
    }
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    LJOfflineHeadView* headView=[tableView dequeueReusableHeaderFooterViewWithIdentifier:headIdentify];
    if (section==0) {
        headView.nameLabel.text=@"直辖市";
        headView.sizeLabel.text=@"暂无";
    }else{
        MAOfflineProvince* province=self.provincesArray[section];
        headView.nameLabel.text=province.name;
        headView.sizeLabel.text=[NSString stringWithFormat:@"%.1fM", province.size/1024/1024.0f];
    }
    @weakify(self);
    [headView.clickButton addTargetClickHandler:^(id sender, id status) {
        @strongify(self);
        [self showClickCitySection:section];
    }];
    
    return headView;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OfflineTableViewCell* cell=[tableView dequeueReusableCellWithIdentifier:cellIdentify];
    cell.separatorInset=UIEdgeInsetsZero;
    cell.layoutMargins=UIEdgeInsetsZero;
    
    MAOfflineItem* city;
    if (indexPath.section==0) {
        city=self.municipaliteArray[indexPath.row];
    }else{
        MAOfflineProvince* province=self.provincesArray[indexPath.section];
        city=province.cities[indexPath.row];
    }
    
    cell.cityNameLabel.text=city.name;
    cell.sizeLabel.text=[NSString stringWithFormat:@"%.1fM", city.size/1024/1024.0f];
    if (city.itemStatus==MAOfflineItemStatusCached) {
        cell.statusLabel.text=@"有缓存地图";
    }else if (city.itemStatus==MAOfflineItemStatusInstalled){
        cell.statusLabel.text=@"已安装离线地图";
    }else if (city.itemStatus==MAOfflineItemStatusExpired){
        cell.statusLabel.text=@"离线地图已过期";
    }else{
        cell.statusLabel.text=@"点击下载";
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    self.downloadIndexPath=indexPath;
    MAOfflineItem* city;
    if (indexPath.section==0) {
        city=self.municipaliteArray[indexPath.row];
    }else{
        MAOfflineProvince* province=self.provincesArray[indexPath.section];
        city=province.cities[indexPath.row];
    }
    if (city.itemStatus==MAOfflineItemStatusInstalled) {
        [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
        return;
    }
    UIAlertController* alertController=[UIAlertController alertControllerWithTitle:@"下载" message:[NSString stringWithFormat:@"%@的离线地图",city.name] preferredStyle:UIAlertControllerStyleAlert];
    @weakify(self);
    UIAlertAction* downAction=[UIAlertAction actionWithTitle:@"下载" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self downloadOfflineMap:city];
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        @strongify(self);
        [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
    }]];
    [alertController addAction:downAction];
    [self presentViewController:alertController animated:YES completion:nil];
}
-(NSArray<UITableViewRowAction*>*)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath{
    @weakify(self);
    UITableViewRowAction* deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除离线地图" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        @strongify(self);
        MAOfflineItem* city;
        if (indexPath.section==0) {
            city=self.municipaliteArray[indexPath.row];
        }else{
            MAOfflineProvince* province=self.provincesArray[indexPath.section];
            city=province.cities[indexPath.row];
        }
        
//        MAOfflineProvince* province=self.provincesArray[indexPath.section];
//        MAOfflineItem* city=province.cities[indexPath.row];
        [self deleteOfflineMap:city];
        [self.tableView setEditing:NO animated:YES];
    }];
    
    return @[deleteAction];
}


#pragma mark - ================ Action ==================
-(void)showClickCitySection:(NSInteger)section
{
    if (!self.showCity) {
        self.showCity=YES;
    }else{
        if (self.editSection==section) {
            self.showCity=NO;
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.editSection] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }else{
            self.showCity=NO;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.editSection] withRowAnimation:UITableViewRowAnimationFade];
            self.showCity=YES;
        }
    }
    self.editSection=section;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
    if (self.showCity) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.editSection] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.tableView reloadData];
    }
}

-(void)downloadOfflineMap:(MAOfflineItem*)item
{
    if (item == nil || item.itemStatus == MAOfflineItemStatusInstalled)
    {
        [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
        return;
    }
    DLog(@"download :%@", item.name);
    [[MAOfflineMap sharedOfflineMap]downloadItem:item shouldContinueWhenAppEntersBackground:YES downloadBlock:^(MAOfflineItem *downloadItem, MAOfflineMapDownloadStatus downloadStatus, id info) {
        
        /* Manipulations to your application’s user interface must occur on the main thread. */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString* downloadStatusStr=@"";
            if (downloadStatus == MAOfflineMapDownloadStatusWaiting)
            {
                downloadStatusStr=@"：等待下载";
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusStart)
            {
                downloadStatusStr=@"：开始下载";
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusProgress)
            {
                downloadStatusStr=@"：正在下载";
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusCancelled) {
                downloadStatusStr=@"：取消下载";
                [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusCompleted) {
                downloadStatusStr=@"：下载完成";
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusUnzip) {
                downloadStatusStr=@"：下载完成，正在解压缩";
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusError) {
                downloadStatusStr=@"：下载错误";
                [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
            }
            else if(downloadStatus == MAOfflineMapDownloadStatusFinished) {
                [self.tableView deselectRowAtIndexPath:self.downloadIndexPath animated:YES];
                downloadStatusStr=@"";
                [self.tableView reloadData];
                [[NSNotificationCenter defaultCenter]postNotificationName:@"updateMap" object:nil];
            }
            self.title=[NSString stringWithFormat:@"离线地图%@", downloadStatusStr];
        });
    }];
}

- (void)pause:(MAOfflineItem *)item
{
    DLog(@"pause :%@", item.name);
    
    [[MAOfflineMap sharedOfflineMap] pauseItem:item];
}

/**  离线地图解压到 Documents/autonavi/data/vmap 目录下 */
-(void)deleteOfflineMap:(MAOfflineItem*)item
{
    [[MAOfflineMap sharedOfflineMap]deleteItem:item];
    [self.tableView reloadData];
//    [self initData];
    
//    NSArray* paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString* path=[paths firstObject];
//    NSString* fileName=[path stringByAppendingPathComponent:@"autonavi/data/vmap"];
//    NSFileManager* fileManager=[NSFileManager defaultManager];
//    NSArray* fileList=[fileManager contentsOfDirectoryAtPath:fileName error:nil];
//    DLog(@"...%@", fileList);
}







@end
