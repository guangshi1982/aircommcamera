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


#define FREQUENCY 10

@implementation AirSensorInfo


@end


@interface AirSensorManager() <CLLocationManagerDelegate>

@property (nonatomic) CLLocationManager *locationMan;
@property (nonatomic) CMMotionManager *motionMan;
@property (nonatomic) CMMotionActivityManager *activityMan;

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
    }
    
    return self;
}

-(void)proximityStateDidChange:(NSNotification*)notification
{
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // 時間順CLLocation情報配列
}

-(void)start
{
    // 近接センサオン
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    
    // 近接センサ監視
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proximityStateDidChange:)
                                                 name:UIDeviceProximityStateDidChangeNotification
                                               object:nil];
    
    if ([CLLocationManager locationServicesEnabled]) {// GPS
        // 位置情報取得の開始
        [_locationMan startUpdatingLocation];
    }
    
    if ([CLLocationManager headingAvailable]) {// 磁気センサー
        // 何度動いたら更新するか（デフォルトは1度）
        _locationMan.headingFilter = kCLHeadingFilterNone;
        
        // デバイスの度の向きを北とするか（デフォルトは画面上部）
        _locationMan.headingOrientation = CLDeviceOrientationPortrait;
        
        // 向き情報取得の開始
        [_locationMan startUpdatingHeading];
    }
    
    if (_motionMan.accelerometerAvailable) {
        _motionMan.accelerometerUpdateInterval = 1 / FREQUENCY;
        
        CMAccelerometerHandler handler = ^(CMAccelerometerData *data, NSError *error) {
            
        };
        
        [_motionMan startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if (_motionMan.gyroAvailable) {
        _motionMan.gyroUpdateInterval = 1 / FREQUENCY;
        
        CMGyroHandler handler = ^(CMGyroData *data, NSError *error) {
            
        };
        
        [_motionMan startGyroUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
    
    if ([CMMotionActivityManager isActivityAvailable]) {
        CMMotionActivityHandler handler = ^(CMMotionActivity *activity) {
            // 状態が更新されるたびにリアルタイムでラベル更新
            
        };
        
        [_activityMan startActivityUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
    }
}

-(void)stop
{
    // 近接センサオフ
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    
    // 近接センサ監視解除
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceProximityStateDidChangeNotification
                                                  object:nil];
    
    // 位置情報の取得停止
    if ([CLLocationManager locationServicesEnabled]) {
        [_locationMan stopUpdatingLocation];
    }
    // ヘディングイベントの停止
    if ([CLLocationManager headingAvailable]) {
        [_locationMan stopUpdatingHeading];
    }
}

@end
