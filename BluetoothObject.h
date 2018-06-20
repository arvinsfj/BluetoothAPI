//
//  BluetoothObject.h
//  TestCoreBluetooth
//
//  Created by vin on 2018/6/6.
//  Copyright © 2018年 vin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreBluetooth/CoreBluetooth.h>

@class BluetoothObject;

typedef NS_ENUM(NSUInteger, DeviceFilter) {
    DF_NOTIFY = 1,
    DF_READ,
    DF_WRITE,
};

@protocol BluetoothObjectDeviceDelegate <NSObject>
@required
//设备信息回调
- (NSInteger)deviceFilterPeripheral:(CBPeripheral*)peripheral;
- (BOOL)deviceFilterNotifyOrWriteCharacteristic:(CBCharacteristic*)character andPeripheral:(CBPeripheral *)peripheral andFilter:(DeviceFilter)filter;
- (void)deviceSingleMeasureWithBluetooth:(BluetoothObject*)bluetooth;
- (NSInteger)deviceParseData:(NSData *)data andPeripheral:(CBPeripheral *)peripheral;
//设备缓存相关
- (void)deviceSave:(CBPeripheral *)peripheral;
- (BOOL)deviceFilterInCache:(CBPeripheral*)peripheral;

@end

typedef NS_ENUM(NSUInteger, BluetoothState) {
    BS_DISCONN = 1,
    BS_CONNING,
    BS_CONNED,
    BS_NOBTTH,//蓝牙未开启
    BS_CONNLIST,//弹出提示列表
};

@protocol BluetoothObjectDelegate <NSObject>
@optional
//蓝牙连接状态回调
- (void)bluetoothConnState:(BluetoothObject*)bluetooth andState:(BluetoothState)state andError:(NSError*)error;

//数据读写回调
- (void)bluetoothReadData:(BluetoothObject*)bluetooth andData:(NSData*)data andError:(NSError*)error;
- (void)bluetoothReadData:(BluetoothObject*)bluetooth andLength:(NSInteger)length;//返回毫米数据
- (void)bluetoothWriteData:(BluetoothObject*)bluetooth andError:(NSError*)error;

@end

@interface BluetoothObject : NSObject

// 回调代理
@property (nonatomic, weak) id<BluetoothObjectDelegate> delegate;

- (instancetype)initWithDeviceDelegate:(id<BluetoothObjectDeviceDelegate>)deviceInfo;

//设备信息对象使用接口，获取主设备蓝牙状态
- (CBPeripheral*)getPeripheral;
- (void)sendByteWith:(void*)byte andLength:(NSInteger)length;

//开始连接接口
- (void)startBluetooth;

// 获取蓝牙设备状态（是否开启）接口
- (BOOL)getBluetoothDeviceState;
- (NSString*)getPeripheralName;

// 获取连接状态接口
- (BOOL)getBluetoothNotifyState;
- (BOOL)getBluetoothCommandState;
- (BOOL)getBluetoothState;

// 单次测量接口：必须设备支持，否则没有效果
- (void)singleMeasure;

// 当提示BS_CONNLIST状态时获取提示的设备列表
- (NSArray*)getPeripheralNameList;
- (void)connectWithIndex:(NSInteger)index;//主动连接外设

@end
