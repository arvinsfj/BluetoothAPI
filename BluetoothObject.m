//
//  BluetoothObject.m
//  TestCoreBluetooth
//
//  Created by vin on 2018/6/6.
//  Copyright © 2018年 vin. All rights reserved.
//

#import "BluetoothObject.h"

static CBCentralManager* _cbCentralM;//主设备管理器

@interface BluetoothObject () <CBCentralManagerDelegate, CBPeripheralDelegate>

//
@property (nonatomic, strong) id<BluetoothObjectDeviceDelegate> deviceDelegate;//设备信息获取代理
//
@property (nonatomic, strong) CBPeripheral* curPeripheral;//当前连接的外设
@property (nonatomic, strong) NSMutableArray<CBPeripheral *>* peripheralArr;//扫描到的所有外设，因为添加设备和读取设备都是在主线程进行，所以读写是同步的，不会出现问题
//
@property (nonatomic, strong) CBCharacteristic* curNotifyCharacteristic;//当前可订阅特征，数据订阅使用
@property (nonatomic, strong) CBCharacteristic* curWriteCharacteristic;//当前可写入特征，数据命令控制使用

@end

@implementation BluetoothObject

- (void)dealloc
{
    if (_cbCentralM) {
        _cbCentralM = nil;
    }
    if (_peripheralArr) {
        [_peripheralArr removeAllObjects];
    }
}

- (instancetype)initWithDeviceDelegate:(id<BluetoothObjectDeviceDelegate>)deviceInfo
{
    if (self = [super init]) {
        _cbCentralM = nil;
        _curPeripheral = nil;
        _peripheralArr = [[NSMutableArray alloc] init];
        _curNotifyCharacteristic = nil;
        _curWriteCharacteristic = nil;
        //设置device
        _deviceDelegate = deviceInfo;
    }
    return self;
}

///////////////////////////////////////////以上设备相关///////////////////////////////////////

- (void)startBluetooth
{
    if (_cbCentralM) {
        [self disconnect];
    }
    _cbCentralM = nil;
    _curPeripheral = nil;
    [_peripheralArr removeAllObjects];
    _curNotifyCharacteristic = nil;
    _curWriteCharacteristic = nil;
    _cbCentralM = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];//这个队列后面可以换掉
}

// 返回已经连接好的外设对象
- (CBPeripheral*)getPeripheral
{
    if (_curPeripheral && _curPeripheral.state == CBPeripheralStateConnected) {
        return _curPeripheral;
    }
    return nil;
}

- (NSString*)getPeripheralName
{
    CBPeripheral* peripheral = [self getPeripheral];
    if (peripheral) {
        NSString *name = peripheral.name;
        if (name && name.length) {
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            return name;
        } else {
            return @"未知设备";
        }
    }
    return nil;
}

- (BOOL)getBluetoothDeviceState
{
    if (_cbCentralM && _cbCentralM.state == CBManagerStatePoweredOn) {
        return YES;
    }
    return NO;
}

- (BOOL)getBluetoothNotifyState
{
    if ([self getPeripheral] && _curNotifyCharacteristic && _curNotifyCharacteristic.isNotifying) {
        return YES;
    }
    return NO;
}

- (BOOL)getBluetoothCommandState
{
    if ([self getPeripheral] && _curWriteCharacteristic) {
        return YES;
    }
    return NO;
}

- (BOOL)getBluetoothState
{
    if ([self getBluetoothNotifyState] && [self getBluetoothCommandState]) {
        return YES;
    }
    return NO;
}

// 接口
- (void)startScan
{
    [self startScanWithUUIDs:nil];
}

- (void)startScanWithUUIDs:(NSArray<CBUUID *> *)arr
{
    if (_cbCentralM.state == CBManagerStatePoweredOn) {
        [_peripheralArr removeAllObjects];//移除之前的数据
        [_cbCentralM scanForPeripheralsWithServices:arr options:nil];//扫描所有的外设
        //一次性计时2秒
        [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(NSTimer * _Nonnull timer) {
            if (self->_peripheralArr && self->_peripheralArr.count && _cbCentralM.isScanning) {
                //没有扫描到已经连接过的设备，并且扫描到了新设备，弹出新设备连接提示框
                if (self->_delegate && [self->_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
                    [self->_delegate bluetoothConnState:self andState:BS_CONNLIST andError:nil];
                }
            }
        }];
    }
}

- (NSArray*)getPeripheralNameList
{
    NSMutableArray* peripheralNameArr = [[NSMutableArray alloc] init];
    NSArray* tempArr = [[NSArray alloc] initWithArray:_peripheralArr];
    for (CBPeripheral* peripheral in tempArr) {
        NSString *name = peripheral.name;
        if (name && name.length) {
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        } else {
            name = @"未知设备";
        }
        [peripheralNameArr addObject:name];
    }
    return peripheralNameArr;
}

- (void)stopScan
{
    if (_cbCentralM && _cbCentralM.isScanning) {
        [_cbCentralM stopScan];
    }
}

- (void)connect
{
    [self connectWithPeripheral:_curPeripheral];
}

- (void)connectWithIndex:(NSInteger)index
{
    if (index >= 0 && index < _peripheralArr.count) {
        [self connectWithPeripheral:_peripheralArr[index]];
    }
}

- (void)connectWithPeripheral:(CBPeripheral*)peripheral
{
    if (_cbCentralM.state == CBManagerStatePoweredOn && peripheral && peripheral.state == CBPeripheralStateDisconnected) {
        _curPeripheral = peripheral;
        [_cbCentralM connectPeripheral:peripheral options:nil];
    }
}

- (void)connectTryAll
{
    //[self connect];//尝试连接当前设备
}

- (void)disconnect
{
    [self disconnectWithPeripheral:_curPeripheral];
}

- (void)disconnectWithIndex:(NSInteger)index
{
    if (index >= 0 && index < _peripheralArr.count) {
        [self disconnectWithPeripheral:_peripheralArr[index]];
    }
}

- (void)disconnectWithPeripheral:(CBPeripheral*)peripheral
{
    if (_cbCentralM.state == CBManagerStatePoweredOn && peripheral && peripheral.state == CBPeripheralStateConnected) {
        [_cbCentralM cancelPeripheralConnection:peripheral];
    }
}

//以上是接口定义


// 中心设备管理器的回调方法
// 必须回调方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    // 蓝牙可用，开始扫描外设
    if (central.state == CBManagerStatePoweredOn) {
        NSLog(@"蓝牙可用");
        [self startScan];//开始扫描外设
    }
    else if (central.state == CBManagerStatePoweredOff) {
        NSLog(@"蓝牙已关闭");
    }
    else if (central.state == CBManagerStateResetting) {
        NSLog(@"蓝牙重置中");
    }
    else if(central.state == CBManagerStateUnsupported) {
        NSLog(@"该设备不支持蓝牙");
    }
    else if (central.state == CBManagerStateUnauthorized) {
        NSLog(@"蓝牙没有认证");
    }
    else if (central.state == CBManagerStateUnknown) {
        NSLog(@"蓝牙未知状态");
    }
    //蓝牙未开启状态回调
    if (central.state != CBManagerStatePoweredOn) {
        //状态回调
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
            [_delegate bluetoothConnState:self andState:BS_NOBTTH andError:nil];
        }
    }
}

// 下面是可选的回调
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    // 扫描到外设的时候回调
    if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceFilterPeripheral:)]) {
        NSInteger index = [self.deviceDelegate deviceFilterPeripheral:peripheral];//过滤是不是支持的外设
        if (index != -1) {
            //确定是我们支持的设备
            BOOL needAdd = YES;
            if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceFilterInCache:)]) {
                if ([_deviceDelegate deviceFilterInCache:peripheral] && peripheral.state == CBPeripheralStateDisconnected) {
                    //是曾经连接过的设备，直接连接
                    _curPeripheral = peripheral;
                    [self connect];
                    //状态回调
                    if (_delegate && [_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
                        [_delegate bluetoothConnState:self andState:BS_CONNING andError:nil];
                    }
                    [_peripheralArr addObject:peripheral];//加入数组，以便重新连接
                    needAdd = NO; //不需要添加
                }
            }
            if (needAdd && peripheral.state == CBPeripheralStateDisconnected) {
                //新设备，加入到新设备数组中，超时2秒后弹出列表提示框
                [_peripheralArr addObject:peripheral];
            }
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    // 成功连接到外设时回调
    [self stopScan];//停止扫描
    //状态回调
    if (_delegate && [_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
        [_delegate bluetoothConnState:self andState:BS_CONNED andError:nil];
    }
    //保存已经连接过的外设
    if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceSave:)]) {
        [_deviceDelegate deviceSave:peripheral];
    }
    if (![peripheral isEqual:_curPeripheral]) {
        _curPeripheral = peripheral;
    }
    NSLog(@"%@", _curPeripheral.name);
    [self initPeripheral];
    [self startServiceScan];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    // 连接外设失败时回调
    //状态回调
    if (_delegate && [_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
        [_delegate bluetoothConnState:self andState:BS_DISCONN andError:error];
    }
    NSLog(@"Connect Error: %@", error);
    if ([peripheral isEqual:_curPeripheral]) {
        _curPeripheral = nil;
        [self connectTryAll];
    } else {
        _curPeripheral = nil;
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    // 已连接的外设失去连接状态时回调
    //状态回调
    if (_delegate && [_delegate respondsToSelector:@selector(bluetoothConnState:andState:andError:)]) {
        [_delegate bluetoothConnState:self andState:BS_DISCONN andError:error];
    }
    _curPeripheral = nil;
    if (error) {
        NSLog(@"Disconnect: %@", error);
    }
    NSLog(@"断开连接: %@", peripheral.name);
    [self connectTryAll];
}

// 以上是蓝牙连接部分实现

- (void)initPeripheral
{
    [self initPeripheralWith:_curPeripheral];
}

- (void)initPeripheralWith:(CBPeripheral*)peripheral
{
    if (peripheral && peripheral.state == CBPeripheralStateConnected) {
        peripheral.delegate = self;
    }
}

- (void)startServiceScan
{
    [self startServiceScanWith:_curPeripheral];
}

- (void)startServiceScanWith:(CBPeripheral*)peripheral
{
    if (peripheral && peripheral.state == CBPeripheralStateConnected) {
        [peripheral discoverServices:nil];//发现该外设上的所有服务
    }
}

- (void)sendByteWith:(void*)byte andLength:(NSInteger)length
{
    NSData* data = [NSData dataWithBytes:byte length:length];
    [self sendDataWith:data];
}

- (void)sendDataWith:(NSData*)data
{
    [self sendDataWith:_curPeripheral andData:data];
}

- (void)sendDataWith:(CBPeripheral*)peripheral andData:(NSData*)data
{
    if (peripheral && peripheral.state == CBPeripheralStateConnected && _curWriteCharacteristic && data) {
        if ((_curWriteCharacteristic.properties&CBCharacteristicPropertyWrite) != 0) {
            [peripheral writeValue:data forCharacteristic:_curWriteCharacteristic type:CBCharacteristicWriteWithResponse];
        }
        if ((_curWriteCharacteristic.properties&CBCharacteristicPropertyWriteWithoutResponse) != 0) {
            [peripheral writeValue:data forCharacteristic:_curWriteCharacteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

- (void)singleMeasureThread
{
    if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceSingleMeasureWithBluetooth:)]) {
        [_deviceDelegate deviceSingleMeasureWithBluetooth:self];
    }
}

- (void)singleMeasure
{
    NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(singleMeasureThread) object:nil];
    [thread start];
}

// 以下是外设对象的回调方法
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{
    //外设服务无效时回调
    NSLog(@"无效的服务：%@", invalidatedServices);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    //外设上发现服务时回调
    if (!error) {
        for (CBService* service in peripheral.services) {
            NSLog(@"service: %@", service.UUID.UUIDString);
            if (service.isPrimary) {
                [peripheral discoverCharacteristics:nil forService:service];//发现最后的service的所有特征
            }
        }
    } else {
        NSLog(@"%@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    //服务上发现特征时回调
    if (!error) {
        for (CBCharacteristic* character in service.characteristics) {
            NSLog(@"character: %@", character.UUID.UUIDString);
            if ((character.properties&CBCharacteristicPropertyNotify) != 0) {
                NSLog(@"notify character: %@", character.UUID.UUIDString);
                if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceFilterNotifyOrWriteCharacteristic:andPeripheral:andFilter:)]) {
                    if ([_deviceDelegate deviceFilterNotifyOrWriteCharacteristic:character andPeripheral:peripheral andFilter:DF_NOTIFY]) {
                        NSLog(@"%@", @"订阅特征成功！");
                        _curNotifyCharacteristic = character;//获取可订阅特征
                        [peripheral setNotifyValue:YES forCharacteristic:_curNotifyCharacteristic];// 订阅通知
                    }
                }
            }
            if ((character.properties&CBCharacteristicPropertyWrite) != 0 || (character.properties&CBCharacteristicPropertyWriteWithoutResponse) != 0) {
                NSLog(@"write character: %@", character.UUID.UUIDString);
                if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceFilterNotifyOrWriteCharacteristic:andPeripheral:andFilter:)]) {
                    if ([_deviceDelegate deviceFilterNotifyOrWriteCharacteristic:character andPeripheral:peripheral andFilter:DF_WRITE]) {
                        _curWriteCharacteristic = character;//获取可写特征
                        NSLog(@"%@", @"写入特征成功！");
                    }
                }
            }
        }
    } else {
        NSLog(@"%@", error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (!error) {
        if (characteristic.isNotifying) {
            NSLog(@"订阅成功: %@", peripheral.name);
        } else {
            NSLog(@"取消订阅: %@", peripheral.name);
        }
    } else {
        NSLog(@"订阅失败: %@", peripheral.name);
        NSLog(@"%@",error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    //返回read调用的数据
    if (!error) {
        NSLog(@"READ: %@", @"读取成功");
        NSData* data = characteristic.value;
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothReadData:andData:andError:)]) {
            [_delegate bluetoothReadData:self andData:data andError:nil];
        }
        //尝试解析数据
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothReadData:andLength:)]) {
            if (_deviceDelegate && [_deviceDelegate respondsToSelector:@selector(deviceParseData:andPeripheral:)]) {
                NSInteger length = [_deviceDelegate deviceParseData:data andPeripheral:peripheral];
                if (length > 0) {
                    [_delegate bluetoothReadData:self andLength:length];
                }
            }
        }
    } else {
        NSLog(@"%@", error);
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothReadData:andData:andError:)]) {
            [_delegate bluetoothReadData:self andData:nil andError:error];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    //write完成回调
    if (!error) {
        NSLog(@"WRITE: %@", @"写入成功");
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothWriteData:andError:)]) {
            [_delegate bluetoothWriteData:self andError:nil];
        }
    } else {
        NSLog(@"%@", error);
        if (_delegate && [_delegate respondsToSelector:@selector(bluetoothWriteData:andError:)]) {
            [_delegate bluetoothWriteData:self andError:error];
        }
    }
}

//...其他回调不考虑

@end

