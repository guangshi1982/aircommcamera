//
//  AirSensorManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>
#import "AirSensorManager.h"


#define FREQUENCY 5.0

@implementation AirSensorAcceleration

-(id)init
{
    if (self = [super init]) {
        _x = _y = _z = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorRotationRate

-(id)init
{
    if (self = [super init]) {
        _x = _y = _z = 0.0;
        _pitch = _roll = _yaw = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorLocation

-(id)init
{
    if (self = [super init]) {
        _heading = 0.0;
        _headingX = _headingY = _headingZ = 0.0;
    }
    
    return self;
}

@end

@implementation AirSensorActivity

-(id)init
{
    if (self = [super init]) {
        _confidence = 0;
        _unknown = _stationary = _walking = _running = _automotive = _cycling = NO;
    }
    
    return self;
}

@end

@implementation AirSensorRawInfo

-(id)init
{
    if (self = [super init]) {
        _acceleration = [[AirSensorAcceleration alloc] init];
        _rotation = [[AirSensorRotationRate alloc] init];
        _location = [[AirSensorLocation alloc] init];
        _activity = [[AirSensorActivity alloc] init];
    }
    
    return self;
}

@end

@implementation AirSensorInfo

-(id)init
{
    NSLog(@"AirSensorInfo init");
    
    if (self = [super init]) {
        _rawInfo = [[AirSensorRawInfo alloc] init];
    }
    
    return self;
}

@end


@interface AirSensorManager() <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationMan;
@property (nonatomic) CMMotionManager *motionMan;
@property (nonatomic) CMMotionActivityManager *activityMan;
@property (nonatomic) AirSensorInfo *info;

@end



@implementation AirSensorManager

+(AirSensorManager*)getInstance
{
    static AirSensorManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once( &onceToken, ^{
        sharedInstance = [AirSensorManager new];
    });
    
    return sharedInstance;
}

-(id)init
{
    NSLog(@"AirSensorManager init");
    if (self = [super init]) {
        _locationMan = [[CLLocationManager alloc] init];
        _locationMan.delegate = self;
        
        _motionMan = [[CMMotionManager alloc] init];
        _activityMan = [[CMMotionActivityManager alloc] init];
        
        _info = [[AirSensorInfo alloc] init];
    }
    
    return self;
}

-(void)notifySensorInfo
{
    NSLog(@"notifySensorInfo");
    
    if (_observer != nil) {
        if ([_observer respondsToSelector:@selector(sensorInfo:)]) {
            [_observer sensorInfo:_info];
        }
    }
}

-(void)proximityStateDidChange:(NSNotification*)notification
{
    NSLog(@"proximityStateDidChange");
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    NSLog(@"locationManager didUpdateHeading");
    
    CLLocationDirection heading = newHeading.magneticHeading;
    _info.rawInfo.location.heading = heading;
    [self notifySensorInfo];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"locationManager didUpdateLocations");
    // 時間順CLLocation情報配列
}


// todo:すべてcurrentQueueにすると、キューにたまるので、リアルタイムにならない可能性がある
-(void)start:(AirSensorType)type
{
    // 近接センサオン
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    // 近接センサ監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityStateDidChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
    
    if ([CLLocationManager locationServicesEnabled] && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {// GPS
        // 位置情報取得の開始
        [_locationMan startUpdatingLocation];
    }
    
    if ([CLLocationManager headingAvailable] && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {// 磁気センサー
        // 何度動いたら更新するか（デフォルトは1度）
        //_locationMan.headingFilter = kCLHeadingFilterNone;
        _locationMan.headingFilter = 5;
        
        // デバイスの度の向きを北とするか（デフォルトは画面上部）
        _locationMan.headingOrientation = CLDeviceOrientationPortrait;
        
        // 向き情報取得の開始
        [_locationMan startUpdatingHeading];
    }
    
    if (_motionMan.accelerometerAvailable && (type & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {// 加速度(方向[-/+]と速度)
        _motionMan.accelerometerUpdateInterval = 1 / FREQUENCY;
        
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            NSLog(@"CMAccelerometerHandler");
            
            _info.rawInfo.acceleration.x = data.acceleration.x;
            _info.rawInfo.acceleration.y = data.acceleration.y;
            _info.rawInfo.acceleration.z = data.acceleration.z;
            
            [self notifySensorInfo];
        };
        
        [_motionMan startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if (_motionMan.gyroAvailable && (type & AirSensorTypeRotationRate) == AirSensorTypeRotationRate) {// 角速度(方向[-/+]と速度)
        _motionMan.gyroUpdateInterval = 1 / FREQUENCY;
        
        CMGyroHandler handler = ^(CMGyroData *data, NSError *error) {
            NSLog(@"CMGyroHandler");
            
            _info.rawInfo.rotation.x = data.rotationRate.x;
            _info.rawInfo.rotation.y = data.rotationRate.y;
            _info.rawInfo.rotation.z = data.rotationRate.z;
            
            [self notifySensorInfo];
        };
        
        [_motionMan startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if (_motionMan.deviceMotionAvailable && (type & AirSensorTypeRotationRate) == AirSensorTypeRotationRate) {// 回転角度
        _motionMan.deviceMotionUpdateInterval = 1 / FREQUENCY;
        
        CMDeviceMotionHandler handler = ^(CMDeviceMotion *data, NSError *error) {
            NSLog(@"CMDeviceMotionHandler");
            
            _info.rawInfo.rotation.pitch = data.attitude.pitch;
            _info.rawInfo.rotation.roll = data.attitude.roll;
            _info.rawInfo.rotation.yaw = data.attitude.yaw;
            
            [self notifySensorInfo];
        };
        
        [_motionMan startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if (_motionMan.magnetometerAvailable && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {
        _motionMan.magnetometerUpdateInterval = 1 / FREQUENCY;
        
        CMMagnetometerHandler handler = ^(CMMagnetometerData *data, NSError *error) {
            NSLog(@"CMMagnetometerHandler");
            
            _info.rawInfo.location.headingX = data.magneticField.x;
            _info.rawInfo.location.headingY = data.magneticField.y;
            _info.rawInfo.location.headingZ = data.magneticField.z;
            
            [self notifySensorInfo];
        };
        
        [_motionMan startMagnetometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (type & AirSensorTypeActivity) == AirSensorTypeActivity) {
        CMMotionActivityHandler handler = ^(CMMotionActivity *activity) {
            // 状態が更新されるたびにリアルタイムでラベル更新
            NSLog(@"CMMotionActivityHandler");
            
            _info.rawInfo.activity.confidence = activity.confidence;
            _info.rawInfo.activity.unknown = activity.unknown;
            _info.rawInfo.activity.stationary = activity.stationary;
            _info.rawInfo.activity.walking = activity.walking;
            _info.rawInfo.activity.running = activity.running;
            _info.rawInfo.activity.automotive = activity.automotive;
            _info.rawInfo.activity.cycling = activity.cycling;
            
            [self notifySensorInfo];
        };
        
        [_activityMan startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}

-(void)stop:(AirSensorType)type
{
    // 近接センサオフ
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    // 近接センサ監視解除
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    
    // 位置情報の取得停止
    if ([CLLocationManager locationServicesEnabled] && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {
        [_locationMan stopUpdatingLocation];
    }
    // ヘディングイベントの停止
    if ([CLLocationManager headingAvailable] && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {
        [_locationMan stopUpdatingHeading];
    }
    
    if (_motionMan.accelerometerActive && (type & AirSensorTypeAcceleration) == AirSensorTypeAcceleration) {
        [_motionMan stopAccelerometerUpdates];
    }
    
    if (_motionMan.gyroActive && (type & AirSensorTypeRotationRate) == AirSensorTypeRotationRate) {
        [_motionMan stopGyroUpdates];
    }
    
    if (_motionMan.deviceMotionActive && (type & AirSensorTypeRotationRate) == AirSensorTypeRotationRate) {
        [_motionMan stopDeviceMotionUpdates];
    }
    
    if (_motionMan.magnetometerActive && (type & AirSensorTypeLocation) == AirSensorTypeLocation) {
        [_motionMan stopMagnetometerUpdates];
    }
    
    if ([CMMotionActivityManager isActivityAvailable] && (type & AirSensorTypeActivity) == AirSensorTypeActivity) {
        [_activityMan stopActivityUpdates];
    }
}

@end
