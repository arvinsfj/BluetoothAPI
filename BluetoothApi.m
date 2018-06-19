//
//  BluetoothApi.m
//  TestCoreBluetooth
//
//  Created by vin on 2018/6/7.
//  Copyright © 2018年 vin. All rights reserved.
//

#import "BluetoothApi.h"

@implementation BluetoothApi

+ (instancetype)shareInstance
{
    static BluetoothApi * _singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_singleton == nil) {
            _singleton = [[BluetoothApi alloc] initWithDeviceDelegate:[[DeviceInfoObject alloc] init]];
        }
    });
    return _singleton;
}

@end
