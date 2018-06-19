//
//  BluetoothApi.h
//  TestCoreBluetooth
//
//  Created by vin on 2018/6/7.
//  Copyright © 2018年 vin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BluetoothObject.h"
#import "DeviceInfoObject.h"

@interface BluetoothApi : BluetoothObject

+ (instancetype)shareInstance;

@end
