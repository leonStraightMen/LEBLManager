//
//  LEBLManager.h
//  Unity-iPhone
//
//  Created by Leon on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

//设备类型
typedef NS_ENUM(NSInteger, DEVICE_TYPE){
    DEVICETYPE_MAIN =0, //主设备
    DEVICETYPE_VICE, //副设备
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark ------------------- block的定义 --------------------------
/** 蓝牙状态改变的block */
typedef void(^LEStateUpdateBlock)(CBCentralManager *central);

/** 发现一个蓝牙外设的block */
typedef void(^LEDiscoverPeripheralBlock)(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI);

///** 连接完成的block,失败error就不为nil */
//typedef void(^LEConnectCompletionBlock)(CBPeripheral *peripheral, NSError *error);

/** 蓝牙连接成功的回调*/
typedef void(^LEBluedConnectSuccessfulBlock)(CBPeripheral *peripheral);

/** 蓝牙链接失败的回调 */
typedef void(^LEBluedConnectFailureBlock)(NSError *error);

/** 蓝牙链接已经断开的回调 */
typedef void(^LEBluedIsDisConnectBlock)(CBPeripheral *peripheral,NSError *error);

/** 搜索到服务block */
typedef void(^LEDiscoveredServicesBlock)(CBPeripheral *peripheral, NSArray *services, NSError *error);

/** 搜索到某个服务中的特性的block */
typedef void(^LEDiscoverCharacteristicsBlock)(CBPeripheral *peripheral, CBService *service, NSArray *characteristics, NSError *error);

/** 收到摸个特性中数据的回调 */
typedef void(^LEReadValueForCharacteristicBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic, NSData *value, NSError *error,DEVICE_TYPE type);

/** 往特性中写入数据的回调 */
typedef void(^LEWriteToCharacteristicBlock)(CBPeripheral *peripheral,CBCharacteristic *characteristic, NSError *error,DEVICE_TYPE type);

@interface LEONBLManager : NSObject

//蓝牙外设
@property(nonatomic,copy)LEStateUpdateBlock  stateUpdateBlock;
@property(nonatomic,copy)LEDiscoverPeripheralBlock  discoverPeripheralBlock;
@property(nonatomic,copy)LEBluedConnectSuccessfulBlock  successfulBlock;
@property(nonatomic,copy)LEBluedConnectFailureBlock  connectFailureBlock;
@property(nonatomic,copy)LEBluedIsDisConnectBlock  disConnectBlock;
//蓝牙数据
@property(nonatomic,copy)LEDiscoveredServicesBlock  discoveredServicesBlock;//
@property(nonatomic,copy)LEDiscoverCharacteristicsBlock  discoverCharacteristicsBlock;
@property(nonatomic,copy)LEReadValueForCharacteristicBlock  readValueForCharacteristicBlock;
@property(nonatomic,copy)LEWriteToCharacteristicBlock  writeToCharacteristicBlock;//

@property(nonatomic,strong)CBPeripheral * peripheral;//主设备
@property(nonatomic,strong)CBPeripheral * vicePeripheral;//副设备

//主设备 写入数据的特征 读取数据的特征
@property(nonatomic,strong)CBCharacteristic * write;
@property(nonatomic,strong)CBCharacteristic * read;

//副设备 写入数据的特征 读取数据的特征
@property(nonatomic,strong)CBCharacteristic * viceWrite;
@property(nonatomic,strong)CBCharacteristic * viceRead;

/**
 声明单例类
 */
+(instancetype)sharedInstance;

#pragma mark -------------- public methon ==>> 外部 操作CBCentralManager
/**
 初始外设管理类
 */
-(void)initCBCentralManager;

/**
 开始扫描蓝牙外设
 @param serviceUUIDs 一个CBUUID对象表示要扫描的服务。
 @param options 一个可选的字典，指定扫描选项
 */
- (void)scanForPeripheralsWithServices:(nullable NSArray<CBUUID *> *)serviceUUIDs options:(nullable NSDictionary<NSString *, id> *)options;
/**
 停止扫描蓝牙外设
 */
- (void)stopScan;
 
/**
 外部主动断开蓝牙链接
 @param peripheral 待链接的CBPeripheral对象
 @param options 一个可选的字典，指定连接行为选项
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options;

/**
 外部主动断开蓝牙链接
 @param peripheral 待断开的CBPeripheral对象
 */
- (void)cancelPeripheralConnection;

#pragma mark -------------- public methon ==>> 外部 操作 CBPeripheral

/**
 主动向蓝牙写入数据
 @param data 数据流
 @param characteristic 可以写入的特征
 @param type 写入数据的类型
 */
- (void)writeValue:(NSData *)data forCharacteristic:(CBCharacteristic *)characteristic writeType:(CBCharacteristicWriteType)writeType deviceType:(DEVICE_TYPE)deviceType;

@end

NS_ASSUME_NONNULL_END
