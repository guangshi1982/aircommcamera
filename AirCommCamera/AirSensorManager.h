//
//  AirSensorManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    AirSensorTypeAcceleration = 1,
    AirSensorTypeRotationRate = 2,
    AirSensorTypeLocation     = 4,
    AirSensorTypeActivity     = 8
} AirSensorType;

/*
typedef struct {
    double x;
    double y;
    double z;
} AirSensorAcceleration;

typedef struct {
    double x;
    double y;
    double z;
} AirSensorRotationRate;

typedef struct {
    double heading;
} AirSensorLocation;

typedef struct {
    int confidence;
    BOOL stationary;
    BOOL walking;
    BOOL running;
    BOOL cycling;
    BOOL unknown;
} AirSensorActivity;

typedef struct {
    AirSensorAcceleration acceleration;
    AirSensorRotationRate rotation;
    AirSensorLocation location;
    AirSensorActivity activity;
} AirSensorRawInfo;
 */

@interface AirSensorAcceleration : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;

@end

@interface AirSensorRotationRate : NSObject

@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;
@property (nonatomic) double pitch;
@property (nonatomic) double roll;
@property (nonatomic) double yaw;

@end

@interface AirSensorLocation : NSObject

@property (nonatomic) double heading;
@property (nonatomic) double headingX;
@property (nonatomic) double headingY;
@property (nonatomic) double headingZ;

@end

@interface AirSensorActivity : NSObject

@property (nonatomic) int confidence;
@property (nonatomic) BOOL unknown;
@property (nonatomic) BOOL stationary;
@property (nonatomic) BOOL walking;
@property (nonatomic) BOOL running;
@property (nonatomic) BOOL automotive;
@property( nonatomic) BOOL cycling;

@end

@interface AirSensorRawInfo : NSObject

@property (nonatomic) AirSensorAcceleration *acceleration;
@property (nonatomic) AirSensorRotationRate *rotation;
@property (nonatomic) AirSensorLocation *location;
@property (nonatomic) AirSensorActivity *activity;

@end

@interface AirSensorInfo : NSObject

//@property (nonatomic) AirSensorRawInfo rawInfo;
@property (nonatomic) AirSensorRawInfo *rawInfo;

@end


// todo:API名検討
@protocol AirSensorObserver <NSObject>

@optional
// 検知範囲(カメラ起動エリアなど)。GPS/磁気センサーで場所と方向で判断
-(void)isValidArea:(BOOL)valid rawInfo:(AirSensorInfo*)info;
// カメラ画面表示するか。接近センサーで判断
-(void)displayCameraView:(BOOL)flag info:(AirSensorInfo*)info;
// カメラでキャプチャするか。加速度/ジャイロセンサーで判断
-(void)captureImage:(BOOL)flag info:(AirSensorInfo*)info;
// debug
-(void)sensorInfo:(AirSensorInfo*)info;

@end

// todo:汎用的にする
@interface AirSensorManager : NSObject

@property (nonatomic, weak) id<AirSensorObserver> observer;

+(AirSensorManager*)getInstance;
-(void)start:(AirSensorType)type;
-(void)stop:(AirSensorType)type;

@end
