//
//  BLEConnView.m
//  AJJ-Measure
//
//  Created by vin on 2018/6/15.
//

#import "BLEConnView.h"

#import "BluetoothApi.h"

#import "UIButton+ActivityView.h"

@interface BLEConnView () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView* alertView;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) UIButton* retryBtn;
//
@property (nonatomic, strong) NSMutableArray* deviceArr;
@property (nonatomic, assign) NSInteger index;

@end

@implementation BLEConnView

- (void)dealloc
{
    if (_deviceArr) {
        [_deviceArr removeAllObjects];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        //
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.deviceArr = [[NSMutableArray alloc] init];
        self.index = 0;
        [self initAlertWithFrame:CGRectMake((CGRectGetWidth(frame)-290)/2, (CGRectGetHeight(frame)-275)/2, 290, 275)];
        NSArray* nameArr = [[BluetoothApi shareInstance] getPeripheralNameList];
        if (nameArr && nameArr.count) {
            [_deviceArr addObjectsFromArray:nameArr];
            [_tableView reloadData];
        }
    }
    return self;
}

- (instancetype)init
{
    if (self = [self initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)]) {
        //
    }
    return self;
}

- (void)initAlertWithFrame:(CGRect)frame
{
    //初始化alertView
    _alertView = [[UIView alloc] initWithFrame:frame];
    _alertView.backgroundColor = UIColorFromRGB(0xFBF7F6);
    _alertView.layer.cornerRadius = 10;
    _alertView.layer.masksToBounds = YES;
    [self addSubview:_alertView];
    //设置header
    UILabel* headerLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), 50)];
    headerLbl.text = @"扫描到的设备";
    headerLbl.textColor = UIColorFromRGB(0x333333);
    headerLbl.font = FONT(18);
    headerLbl.textAlignment = NSTextAlignmentCenter;
    [_alertView addSubview:headerLbl];
    UIButton* closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(CGRectGetWidth(frame)-2-45, (50-45)/2, 45, 45);
    [closeBtn setImage:[UIImage imageNamed:@"icon_close"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:closeBtn];
    UIImageView* line1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 50, CGRectGetWidth(frame), 1)];
    line1.backgroundColor = UIColorFromRGB(0xC8C7CC);
    [_alertView addSubview:line1];
    //设置中间的外设列表
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 50, CGRectGetWidth(frame), CGRectGetHeight(frame)-100) style:UITableViewStylePlain];
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_alertView addSubview:_tableView];
    //设置footer
    UIImageView* line2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-51, CGRectGetWidth(frame), 1)];
    line2.backgroundColor = UIColorFromRGB(0xC8C7CC);
    [_alertView addSubview:line2];
    _retryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _retryBtn.frame = CGRectMake(0, CGRectGetHeight(frame)-50, CGRectGetWidth(frame)/2, 50);
    _retryBtn.backgroundColor = [UIColor clearColor];
    [_retryBtn setTitle:@"重新扫描" forState:UIControlStateNormal];
    [_retryBtn setTitleColor:UIColorFromRGB(0x333333) forState:UIControlStateNormal];
    _retryBtn.titleLabel.font = FONT(16);
    [_retryBtn addTarget:self action:@selector(retryBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:_retryBtn];
    UIButton* connBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    connBtn.frame = CGRectMake(CGRectGetWidth(frame)/2, CGRectGetHeight(frame)-50, CGRectGetWidth(frame)/2, 50);
    connBtn.backgroundColor = UIColorFromRGB(0x03C77B);
    [connBtn setTitle:@"连接" forState:UIControlStateNormal];
    [connBtn setTitleColor:UIColorFromRGB(0xffffff) forState:UIControlStateNormal];
    connBtn.titleLabel.font = FONT(16);
    [connBtn addTarget:self action:@selector(connBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_alertView addSubview:connBtn];
}

- (void)closeBtnClicked:(UIButton*)btn
{
    NSLog(@"%@", @"close");
    if (self.closeAction) {
        self.closeAction();
    }
    [self removeFromSuperview];
}

- (void)refreshDeviceList
{
    //刷新外设列表
    [_retryBtn stopActivityIndicator];//结束扫描活动指示
    _retryBtn.userInteractionEnabled = YES;
    NSArray* tempArr = [[BluetoothApi shareInstance] getPeripheralNameList];
    if (tempArr && tempArr.count) {
        self.index = 0;
        [_deviceArr removeAllObjects];
        [_deviceArr addObjectsFromArray:tempArr];
        [_tableView reloadData];
    }
}

- (void)retryBtnClicked:(UIButton*)btn
{
    NSLog(@"%@", @"retry");
    //重新扫描外设
    [[BluetoothApi shareInstance] startBluetooth];
    _retryBtn.userInteractionEnabled = NO;
    [_retryBtn startActivityIndicator];//开始扫描活动指示
}

- (void)connBtnClicked:(UIButton*)btn
{
    NSLog(@"%@", @"conn");
    if (self.connAction) {
        self.connAction(self.index);//选中的index
    }
    //连接index设备
    [[BluetoothApi shareInstance] connectWithIndex:self.index];
    [self removeFromSuperview];
}

//////////列表代理方法//////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //被选择
    self.index = indexPath.row;
    [tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* cellId = @"CELLID";
    DeviceTableCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[DeviceTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId andFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 44)];
        cell.backgroundColor = [UIColor clearColor];//透明
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    //
    cell.nameLbl.text = _deviceArr[indexPath.row];
    if (indexPath.row == self.index) {
        cell.nameLbl.textColor = UIColorFromRGB(0x03C77B);
        cell.flagBtn.selected = YES;
    } else {
        cell.nameLbl.textColor = UIColorFromRGB(0x000000);//默认黑色
        cell.flagBtn.selected = NO;
    }
    if (indexPath.row == _deviceArr.count-1 && _deviceArr.count > 3) {
        //最后一个cell，分割线隐藏
        cell.line.hidden = YES;
    } else {
        cell.line.hidden = NO;
    }
    return cell;
}

@end

@interface DeviceTableCell()

@end

@implementation  DeviceTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier andFrame:(CGRect)frame
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //
        [self initSubViewWithFrame:frame];
    }
    return self;
}

- (void)initSubViewWithFrame:(CGRect)frame
{
    //设置nameLbl
    _nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, CGRectGetWidth(frame)-15-CGRectGetHeight(frame), CGRectGetHeight(frame))];
    _nameLbl.font = FONT(16);
    [self addSubview:_nameLbl];
    //设置flagBtn
    _flagBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _flagBtn.frame = CGRectMake(CGRectGetWidth(frame)-CGRectGetHeight(frame), 0, CGRectGetHeight(frame), CGRectGetHeight(frame));
    _flagBtn.backgroundColor = [UIColor clearColor];
    [_flagBtn setImage:[UIImage imageNamed:@"icon_duanxuan_n"] forState:UIControlStateNormal];
    [_flagBtn setImage:[UIImage imageNamed:@"icon_danxuan_p"] forState:UIControlStateSelected];
    _flagBtn.userInteractionEnabled = NO;
    [self addSubview:_flagBtn];
    //设置line
    _line = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(frame)-1, CGRectGetWidth(frame), 1)];
    _line.backgroundColor = UIColorFromRGB(0xC8C7CC);
    [self addSubview:_line];
}

@end
