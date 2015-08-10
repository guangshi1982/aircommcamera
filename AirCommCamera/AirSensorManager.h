//
//  AirSensorManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct {
    double x;
    double y;
    double z;
} AirSensorAcceleration;

typedef struct {
    double x;
    double y;
    double z;
} AirRotationRate;

typedef struct {
    int confidence;
    BOOL stationary;
    BOOL walking;
    BOOL running;
    BOOL cycling;
    BOOL unknown;
} AirActivity;

typedef struct {
    AirSensorAcceleration acceleration;
    AirRotationRate rotation;
    AirActivity activity;
} AirSensorRawInfo;

@interface AirSensorInfo : NSObject

@property (readonly, nonatomic) AirSensorRawInfo raw;

@end


// todo:API名検討
@protocol AirSensorObserver <NSObject>

@optional
// 検知範囲(カメラ起動エリアなど)。GPS/磁気センサーで場所と方向で判断
-(void)isValidArea:(BOOL)valid rawInfo:(AirSensorRawInfo)rawInfo;
// カメラ画面表示するか。接近センサーで判断
-(void)displayCameraView:(BOOL)flag rawInfo:(AirSensorRawInfo)rawInfo;
// カメラでキャプチャするか。加速度/ジャイロセンサーで判断
-(void)captureImage:(BOOL)flag rawInfo:(AirSensorRawInfo)rawInfo;

@end

// todo:汎用的にする
@interface AirSensorManager : NSObject

@property (nonatomic, weak) id<AirSensorObserver> observer;

+(AirSensorManager*)getInstance;
-(void)start;
-(void)stop;

@end
