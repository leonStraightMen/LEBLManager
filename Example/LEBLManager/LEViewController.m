//
//  LEViewController.m
//  LEBLManager
//
//  Created by leonStraightMen on 06/21/2021.
//  Copyright (c) 2021 leonStraightMen. All rights reserved.
//

#import "LEViewController.h"
#import <LEONBLManager.h>
#define LEManager [LEONBLManager sharedInstance]

@interface LEViewController ()

@end

@implementation LEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    //货拉拉拉不拉拉布拉多要看货拉拉拉不拉拉布拉多时拉布拉屎
    [self initCBCentralManager];
    
}

#pragma mark ============================================================== leon new manager
//测试自己封装的蓝牙类
-(void)initCBCentralManager{
            
    if (LEManager.peripheral == nil && LEManager.vicePeripheral == nil){//主副设备都未建立链接 初始化CBCentralManager
        [LEManager initCBCentralManager];
        
    }else{//主/副设备有一个已经建立连接 直接开始扫描外设
        [LEManager scanForPeripheralsWithServices:nil options:nil];
    }
    
    LEManager.stateUpdateBlock = ^(CBCentralManager *  central){
        switch(central.state){
            case 0:
                NSLog(@"当前的蓝牙状态 ===>> CBCentralManagerStateUnknown");
                break;
            case 1:
                NSLog(@"当前的蓝牙状态 ===>> CBCentralManagerStateResetting");
                break;
            case 2:
                NSLog(@"当前的蓝牙状态 ===>> CBCentralManagerStateUnsupported");
                break;
            case 3:
                NSLog(@"当前的蓝牙状态 ===>> CBCentralManagerStateUnauthorized");
                break;
            case 4:{
                NSLog(@"当前的蓝牙状态 ===>> 蓝牙已关闭");
                }
                break;
            case 5:{
                NSLog(@"当前的蓝牙状态 ===>> 蓝牙已开启");//蓝牙已开启
                //扫描蓝牙外设
                [LEManager scanForPeripheralsWithServices:nil options:nil];
            }
                break;
            default:
                break;
        }
        
    };
    
    //发现蓝牙
    LEManager.discoverPeripheralBlock = ^(CBCentralManager * _Nonnull central, CBPeripheral * _Nonnull peripheral, NSDictionary * _Nonnull advertisementData, NSNumber * _Nonnull RSSI){
        
        NSLog(@"扫描发现蓝牙设备advertisementData =  %@",advertisementData);
        //指定扫描出来的peripheral外设哪一台是你要指定的 主/副设备
        if (peripheral.name.length>0&& [peripheral.name hasPrefix:@"耳机_first"]){
            
            LEManager.peripheral = peripheral;
            [self connectBLEManagerData:peripheral deviceType:DEVICETYPE_MAIN];
            
        }else if (peripheral.name.length>0&& [peripheral.name hasPrefix:@"耳机_second"]){
            
            LEManager.vicePeripheral = peripheral;
            [self connectBLEManagerData:peripheral deviceType:DEVICETYPE_VICE];

        }
        
    };

}

//链接主/副设备 + 绑定特征
-(void)connectBLEManagerData:(CBPeripheral*)peripheral deviceType:(DEVICE_TYPE)deviceType{
    
    //链接蓝牙 此时 LEManager.peripheral || LEManager.vicePeripheral 还未init
    [LEManager connectPeripheral:peripheral options:nil];
    //发现服务和特征
    LEManager.discoverCharacteristicsBlock = ^(CBPeripheral * _Nonnull peripheral, CBService * _Nonnull service, NSArray * _Nonnull characteristics, NSError * _Nonnull error){
        
        if (peripheral==LEManager.peripheral&&deviceType==DEVICETYPE_MAIN){//主设备
            
            for (CBCharacteristic * cha in service.characteristics){
                
                if (cha.properties == 12){//写
                    
                    LEManager.write = cha;

                }else if (cha.properties == 16){//读
                    
                    LEManager.read  = cha;
                    [LEManager.peripheral readValueForCharacteristic:cha];
                    [LEManager.peripheral setNotifyValue:YES forCharacteristic:cha];
                    
                }

            }

        }else if (peripheral==LEManager.vicePeripheral&&deviceType==DEVICETYPE_VICE){//副设备

            for (CBCharacteristic * cha in service.characteristics){
                
                if (cha.properties == 12){//写

                    LEManager.viceWrite = cha;

                }else if (cha.properties == 16){//读

                    LEManager.viceRead  = cha;
                    [LEManager.vicePeripheral readValueForCharacteristic:cha];
                    [LEManager.vicePeripheral setNotifyValue:YES forCharacteristic:cha];

                }
            }
        }
    };
    
    //读取特征的报文数据
    LEManager.readValueForCharacteristicBlock = ^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSData * _Nonnull value, NSError * _Nonnull error, DEVICE_TYPE type){
        
        if (deviceType==DEVICETYPE_MAIN){//主设备
            
            NSLog(@"接收到的数据data = %@  设备类型 = %ld",characteristic.value,(long)type);
            
        }else if (deviceType==DEVICETYPE_VICE){//副设备动作数据
 
            NSLog(@"接收到的数据data = %@  设备类型 = %ld",characteristic.value,(long)type);

        }
        
    };

    //写入数据成功的回调
    LEManager.writeToCharacteristicBlock = ^(CBPeripheral * _Nonnull peripheral,CBCharacteristic * _Nonnull characteristic, NSError * _Nonnull error, DEVICE_TYPE type){
        
    };
    
}

//设置震动
- (void)testSendData:(DEVICE_TYPE)deviceType duration:(int)duration{
    
    //
     NSMutableData * writeData = [NSMutableData new];
     Byte header = 0xaa;
     Byte length = 0x05;
     Byte cmd = 0xA1;
     short  ms = 400;
     Byte mslow = (Byte) (0x00FF & ms);//定义第一个byte
     Byte mshigh = (Byte) (0x00FF & (ms>>8));//定义第二个byte
    //传输数据 Byte -->> NSData
     Byte newByte[] = {header,length,cmd,mshigh,mslow};
     writeData = [[NSMutableData alloc] initWithBytes:newByte length:sizeof(newByte)];

    if (deviceType==DEVICETYPE_MAIN){
        NSLog(@"主设备 发送报文  %@", writeData);
        [LEManager writeValue:writeData forCharacteristic:LEManager.write writeType:CBCharacteristicWriteWithResponse deviceType:DEVICETYPE_MAIN];
    }else if (deviceType == DEVICETYPE_VICE){
        NSLog(@"副设备 发送报文  %@", writeData);
        [LEManager writeValue:writeData forCharacteristic:LEManager.viceWrite writeType:CBCharacteristicWriteWithResponse deviceType:DEVICETYPE_VICE];
    }
    
}

@end
