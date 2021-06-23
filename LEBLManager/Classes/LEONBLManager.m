//
//  LEONBLManager.m
//  Unity-iPhone
//
//  Created by Leon on 2021/4/23.

#import "LEONBLManager.h"

//CBCentralManagerDelegate 蓝牙外设回调代理
//CBPeripheralDelegate 蓝牙链接后的数据回调代理
@interface LEONBLManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong, nonatomic)CBCentralManager * centralManager;/**< 蓝牙中心管理器 */

@end

@implementation LEONBLManager

#pragma mark --------------------------------------- public methon ==>> 单例
static LEONBLManager * instance;
//[[self alloc] init] 类方法使用self时，self代表类本身即Class
//类方法中不能访问“属性”和“实例变量”，只能访问“类”对象
+(instancetype)sharedInstance{
//    NSLog(@"LEONBLManager === 1");
     return [[self alloc] init];
}

//初始化一个对象的时候，[[Class alloc] init]，其实是做了两件事。
//alloc 给对象分配内存空间，init是对对象的初始化，包括设置成员变量初值这些工作。
//而给对象分配空间，除了alloc方法之外，还有另一个方法： allocWithZone.
//使用alloc方法初始化一个类的实例的时候，默认是调用了allocWithZone的方法。为了保持单例类实例的唯一性，需要覆盖所有会生成新的实例的方法，如果初始化这个单例类的时候不走[[Class alloc] init] ，而是直接 allocWithZone， 那么这个单例就不再是单例了，所以必须把这个方法也堵上。
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
//  NSLog(@"LEONBLManager === 2");
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      instance = [super allocWithZone:zone];
  });
  return instance;
    
}

//实例对象能访问“属性”和“实例变量”
- (instancetype)init{
    
//    NSLog(@"LEONBLManager === 3");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super init];
        [self initCBCentralManager];
    });
    return instance;
    
}

/**
 初始外设管理类
 */
-(void)initCBCentralManager{
    //蓝牙没打开时alert提示框
    NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey:@(YES)};
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:options];
}

#pragma mark ---------------- public methon ==>> 外部 操作蓝牙外设
/**
 开始扫描蓝牙外设
 @param serviceUUIDs 一个CBUUID对象表示要扫描的服务。
 @param options 一个可选的字典，指定扫描选项
 */
- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options{
    [self.centralManager scanForPeripheralsWithServices:serviceUUIDs options:options];
    NSLog(@"开始扫描外设");
}

/**
 停止扫描蓝牙外设
 */
- (void)stopScan{
    [self.centralManager stopScan];
    NSLog(@"停止扫描外设");
}
 
/**
 外部主动断开蓝牙链接
 @param peripheral 待链接的CBPeripheral对象
 @param options 一个可选的字典，指定连接行为选项
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options{
    
    if (peripheral==self.peripheral){
        [self.centralManager connectPeripheral:self.peripheral options:options];
        NSLog(@"主设备 主动连接蓝牙外设 = %@  %p  %p",self.peripheral.name,self.peripheral,peripheral);
    }else if (peripheral==self.vicePeripheral){
        [self.centralManager connectPeripheral:self.vicePeripheral options:options];
        NSLog(@"副设备 主动连接蓝牙外设 = %@  %p  %p",self.vicePeripheral.name,self.vicePeripheral,peripheral);
    }
    
}

/**
 外部主动断开蓝牙链接
 @param peripheral 待断开的CBPeripheral对象
 */
- (void)cancelPeripheralConnection{
    
    if (self.peripheral!=nil){
        
        [self.centralManager cancelPeripheralConnection:self.peripheral];
        NSLog(@"主动断开蓝牙链接 = %@",self.peripheral.name);
//        self.peripheral = nil;

    }else if (self.vicePeripheral!=nil){
        
        [self.centralManager cancelPeripheralConnection:self.vicePeripheral];
        NSLog(@"主动断开蓝牙链接 = %@",self.vicePeripheral.name);
//        self.vicePeripheral = nil;

    }

}

#pragma mark -------------- public methon ==>> 外部 操作蓝牙数据
/**
 主动向蓝牙写入数据
 @param data 数据流
 @param characteristic 可以写入的特征
 @param type 写入数据的类型
 */
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic writeType:(CBCharacteristicWriteType)writeType deviceType:(DEVICE_TYPE)deviceType{
    if (deviceType==DEVICETYPE_MAIN){
        [self.peripheral writeValue:data forCharacteristic:characteristic type:writeType];
    }else if (deviceType==DEVICETYPE_VICE){
        [self.vicePeripheral writeValue:data forCharacteristic:characteristic type:writeType];
    }
}

#pragma mark ===================================  CentralManagerDelegate 代理回调
//返回蓝牙状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
//    NSLog(@"蓝牙状态更新 = %ld",(long)central.state);

    if (central!=nil){
        if (_stateUpdateBlock){
            _stateUpdateBlock(central);
        }
    }

}

//扫描发现蓝牙设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    
    if (_discoverPeripheralBlock){
        //过滤无效外设
        if (peripheral.name.length>=1){
//            NSLog(@"扫描发现蓝牙外设 = %@",peripheral.name);
            _discoverPeripheralBlock(central, peripheral, advertisementData, RSSI);

        }
    }
    
}

//蓝牙链接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    if (_successfulBlock){
        _successfulBlock(peripheral);
    }
    
    if (peripheral == self.peripheral){
        NSLog(@"主设备 查找 %@ 的服务",peripheral.name);
        //声明蓝牙delegate
        self.peripheral.delegate = self;
        //serviceUUIDs传nil表示去获取连接到的蓝牙的所有服务
        [self.peripheral discoverServices:nil];
    }else if (peripheral == self.vicePeripheral){
        NSLog(@"副设备 查找 %@ 的服务",peripheral.name);
        //声明蓝牙delegate
        self.vicePeripheral.delegate = self;
        //serviceUUIDs传nil表示去获取连接到的蓝牙的所有服务
        [self.vicePeripheral discoverServices:nil];
    }
 
}

//蓝牙链接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    if (_connectFailureBlock){
        _connectFailureBlock(error);
    }
    
    if (peripheral == self.peripheral){
        NSLog(@"主设备 蓝牙外设链接失败 = %@",peripheral.name);
    }else if (peripheral == self.vicePeripheral){
        NSLog(@"副设备 蓝牙外设链接失败 = %@",peripheral.name);
    }
    
}

//丢失蓝牙链接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
    if (_disConnectBlock){
        _disConnectBlock(peripheral,error);
    }
    if (peripheral == self.peripheral){
        NSLog(@"主设备 蓝牙外设丢失链接 = %@",peripheral.name);
    }else if (peripheral == self.vicePeripheral){
        NSLog(@"副设备 蓝牙外设丢失链接 = %@",peripheral.name);
    }
        
}

#pragma mark =================================== PeripheralDelegate 代理回调
//发现服务的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{

    if (_discoveredServicesBlock){
        _discoveredServicesBlock(peripheral,peripheral.services,error);
    }
    
    if (peripheral == self.peripheral){
        NSLog(@"主设备 查找 %@ 的特征",peripheral.name);
    }else if (peripheral == self.vicePeripheral){
        NSLog(@"主设备 查找 %@ 的特征",peripheral.name);
    }
    
    //扫描所有的特征
    for (CBService *service in peripheral.services){
    [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

//发现特征的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    
//    NSLog(@"发现所有服务+特征的值  %p  %p %p",self.peripheral,self.vicePeripheral,peripheral);

    if (_discoverCharacteristicsBlock){
        
        if (peripheral==self.peripheral){
            
            _discoverCharacteristicsBlock(peripheral,service,service.characteristics,error);
            NSLog(@"主设备 发现 %@ 服务+特征",peripheral.name);

        }else if (peripheral == self.vicePeripheral){
            
            _discoverCharacteristicsBlock(peripheral,service,service.characteristics,error);
            NSLog(@"副设备 发现 %@ 服务+特征",peripheral.name);

        }
        
    }

}

//收到数据的回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    if (_readValueForCharacteristicBlock){
        
        NSData *data = characteristic.value;

        if (peripheral==self.peripheral){
            
            _readValueForCharacteristicBlock(self.peripheral,characteristic,data,error,DEVICETYPE_MAIN);
//            NSLog(@"收到主设备 %@ 推送的报文 %@",peripheral.name,data);

        }else if (peripheral == self.vicePeripheral){
            
            _readValueForCharacteristicBlock(self.vicePeripheral,characteristic,data,error,DEVICETYPE_VICE);
//            NSLog(@"收到副设备 %@ 推送的报文 %@",peripheral.name,data);

        }
        
    }
        
}

//写入数据的回调
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
  
    if (_writeToCharacteristicBlock){
        
        if (peripheral==self.peripheral){
            
            _writeToCharacteristicBlock(self.peripheral,characteristic,error,DEVICETYPE_MAIN);
//            NSLog(@"收到主设备 %@ 的response",peripheral.name);

        }else if (peripheral == self.vicePeripheral){
            
            _writeToCharacteristicBlock(self.vicePeripheral,characteristic,error,DEVICETYPE_VICE);
//            NSLog(@"收到附设备 %@ 的response",peripheral.name);

        }
        
    }

}


@end
