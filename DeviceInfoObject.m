//
//  DeviceInfoObject.m
//  TestCoreBluetooth
//
//  Created by vin on 2018/6/7.
//  Copyright © 2018年 vin. All rights reserved.
//

#import "DeviceInfoObject.h"

#define SIZE_OF(arr) (int)(sizeof(arr)/sizeof(arr[0]))

#define BLE_PERIPHERAL_CACHE_PATH \
[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"ble_peripheral_cache.plist"]

@interface DeviceInfoObject ()

@property (nonatomic, strong) NSArray* productNameArr;//支持的测距仪名称列表
@property (nonatomic, strong) NSArray* productNotifyNameArr;//支持订阅的特征名称列表
@property (nonatomic, strong) NSArray* productWriteNameArr;//支持命令的特征名称列表
@property (nonatomic, assign) IMP* productSingleSendArr;//支持单次测量的函数名称列表
@property (nonatomic, assign) IMP* productDataParseArr;//原始数据解析的函数名称列表

@end

@implementation DeviceInfoObject

- (void)dealloc
{
    free(_productSingleSendArr);
    free(_productDataParseArr);
}

- (instancetype)init
{
    if (self = [super init]) {
        _productNameArr = @[@[@"Myhome3D"],/* 0 厂商设备 */
                            @[@"T40+", @"MX-50", @"T60+", @"PD14 MINI+", @"T100+", @"R40+"],/* 1 厂商设备 */
                            ];
        _productNotifyNameArr = @[@"FFB2", @"CBB1"];
        _productWriteNameArr = @[@"暂无", @"CBB1"];
        
        //单次测量的函数发送列表
        SEL selSendArr[] = {@selector(singleNilSend:), @selector(singleMCSend:), @selector(singleXRDSend:), @selector(singleWCSend:), @selector(singleTRSend:), @selector(singleHLSend:)};//配置列表
        _productSingleSendArr = malloc(SIZE_OF(selSendArr)*sizeof(IMP));
        for (int i = 0; i < SIZE_OF(selSendArr); ++i) {
            IMP func = [self methodForSelector:selSendArr[i]];
            _productSingleSendArr[i] = func;
        }
        
        //设备原始数据解析函数列表
        SEL selParseArr[] = {@selector(deviceAFWParse:), @selector(deviceMCParse:), @selector(deviceXRDParse:), @selector(deviceWCParse:), @selector(deviceTRParse:), @selector(deviceHLParse:)};//配置列表
        _productDataParseArr = malloc(SIZE_OF(selParseArr)*sizeof(IMP));
        for (int i = 0; i < SIZE_OF(selParseArr); ++i) {
            IMP func = [self methodForSelector:selParseArr[i]];
            _productDataParseArr[i] = func;
        }
    }
    return self;
}

- (NSInteger)deviceFilterPeripheral:(CBPeripheral*)peripheral
{
    NSInteger index = -1;
    NSString* peripheralName = peripheral.name;
    
    for (NSArray* pnameArr in _productNameArr) {
        for (NSString* pname in pnameArr) {
            if ([peripheralName containsString:pname]) {
                index = [_productNameArr indexOfObject:pnameArr];
                break;
            }
        }
        if (index != -1) {
            break;
        }
    }
    return index;
}

- (BOOL)deviceFilterNotifyOrWriteCharacteristic:(CBCharacteristic*)character andPeripheral:(CBPeripheral *)peripheral andFilter:(DeviceFilter)filter
{
    NSString* characterName = character.UUID.UUIDString;
    NSInteger index = [self deviceFilterPeripheral:peripheral];//过滤是不是支持的外设
    if (index != -1) {
        //找到了
        NSArray* filterArr = nil;
        if (filter == DF_NOTIFY) {//notify
            filterArr = _productNotifyNameArr;
        } else if (filter == DF_WRITE) {//write
            filterArr = _productWriteNameArr;
        }
        if ([characterName isEqualToString:filterArr[index]]) {
            return YES;
        }
    }
    return NO;
}

//////////////////////////////////下面是单次测量发送方法////////////////////////

//默认协议
- (void)singleNilSend:(BluetoothObject*)bluetooth
{
    //不发送任何指令，作为暂不支持写入命令的设备使用
}

//1设备写协议
- (void)singleXRDSend:(BluetoothObject*)bluetooth
{
    //发送数据
    char data1[] = {0x6B, 0x88};//单次测量
    [bluetooth sendByteWith:data1 andLength:2];
}

//单次测量
- (void)deviceSingleMeasureWithBluetooth:(BluetoothObject*)bluetooth
{
    NSInteger index = -1;
    int num = 0;
    BOOL done = NO;
    while (!done && num < 10) {
        if (![bluetooth getBluetoothState]) {
            num++;
            sleep(1);
        } else {
            index = [self deviceFilterPeripheral:[bluetooth getPeripheral]];
            done = YES;
        }
    }
    if (index != -1 && bluetooth) {
        if (_productSingleSendArr[index]) {
            ((void (*)(id, SEL, id))_productSingleSendArr[index])(self, nil, bluetooth);
        }
    }
}

//////////////////////////////////下面是原始数据解析方法////////////////////////

//默认解析协议
- (NSInteger)deviceNilParse:(NSData*)data
{
    //默认解析方法
    return -1;
}

//0设备读取解析协议
- (NSInteger)deviceAFWParse:(NSData*)data
{
    Byte *byte =(Byte*)[data bytes];
    char bytes[]={byte[3],byte[4],byte[5],byte[6]};
    unsigned char  by1 = (bytes[0] & 0xff); //高8位
    unsigned char  by2 = (bytes[1] & 0xff);//中8位
    unsigned char  by3 = (bytes[2] & 0xff);//低8位
    unsigned char  by4 = (bytes[3] & 0xff);
    int temp = (by4|(by3<<8)|(by2<<16)|(by1<<24));
    NSInteger length = (NSInteger)roundf(temp*0.0001*1000);
    if (length > 0) {
        return length;
    }
    return -1;
}

//1设备读取解析协议
- (NSInteger)deviceXRDParse:(NSData*)data
{
    Byte* receiveByte = (Byte *)[data bytes];
    NSString *strValue = [NSString stringWithCString:(const char *)receiveByte encoding:NSASCIIStringEncoding];
    NSString *result = [strValue componentsSeparatedByString:@"m"].firstObject;
    result = [result stringByReplacingOccurrencesOfString:@"D" withString:@""];
    result = [result stringByReplacingOccurrencesOfString:@"M" withString:@""];
    NSInteger length = (NSInteger)roundf([result floatValue] * 1000);
    if (length > 0) {
        return length;
    }
    return -1;
}

//蓝牙返回的原始数据解析
- (NSInteger)deviceParseData:(NSData *)data andPeripheral:(CBPeripheral *)peripheral
{
    NSInteger index = [self deviceFilterPeripheral:peripheral];
    if (index != -1 && data && data.length) {
        NSInteger length = -1; //正常情况下返回单位位毫米的数据
        if (_productDataParseArr[index]) {
            length = ((NSInteger (*)(id, SEL, id))_productDataParseArr[index])(self, nil, data);
        }
        return length;
    }
    return -1;
}

// 已经连接的蓝牙设备进行写入文件保存
- (void)deviceSave:(CBPeripheral *)peripheral
{
    NSString* filePath = BLE_PERIPHERAL_CACHE_PATH;
    NSMutableArray<NSString*>* pArr = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    if (!pArr) {
        pArr = [[NSMutableArray alloc] init];
    }
    BOOL isHave = NO;
    for (NSString* uuidStr in pArr) {
        if ([uuidStr isEqualToString:peripheral.identifier.UUIDString]) {
            isHave = YES;
            break;
        }
    }
    if (!isHave) {
        [pArr addObject:peripheral.identifier.UUIDString];
        [pArr writeToFile:filePath atomically:YES];
    }
}

// 读取已经缓存过的外设列表（UUID）
- (NSMutableArray*)deviceQuery
{
#ifdef DEBUG
    //[self deviceDeleteCache];
#endif
    NSMutableArray* pArr = [[NSMutableArray alloc] init];
    NSString* filePath = BLE_PERIPHERAL_CACHE_PATH;
    NSMutableArray* tempArr = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    if (tempArr) {
        for (NSString* uuidStr in tempArr) {
            [pArr addObject:[[NSUUID alloc] initWithUUIDString:uuidStr]];
        }
    }
    return pArr;
}

// 过滤外设是否是已经连接过的设备
- (BOOL)deviceFilterInCache:(CBPeripheral*)peripheral
{
    NSMutableArray* pArr = [self deviceQuery];
    for (NSUUID* uuid in pArr) {
        if ([peripheral.identifier.UUIDString isEqualToString:uuid.UUIDString]) {
            return YES;
        }
    }
    return NO;
}

// 删除设备缓存文件，方便调试
- (void)deviceDeleteCache
{
    //
    NSString* filePath = BLE_PERIPHERAL_CACHE_PATH;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

@end
