//
//  AirCameraCapture.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


typedef struct {
    int format;// index in settings
    int fps;
    float exposureValue;
    float iso;
    float bias;
} CameraSetting;

typedef struct {
    float minExposureBias;
    float maxExposureBias;
    float minISO;
    float maxISO;
    float minExposureValue;
    float maxExposureValue;
    float minExposureDuration;
    float maxExposureDuration;
    float minFPS;
    float maxFPS;
} CameraFormat;

typedef struct {
    int format;// index in formats setting
    int fps;
    float exposureDuration;
    float exposureValue;
    float iso;
    float bias;
} CameraCurrentSetting;// for auto mode

@interface CaputureImageInfo : NSObject

@property (nonatomic) UIImage *image;
@property (nonatomic) CMTime timeStamp;
@property (nonatomic) CGSize size;

@end

@protocol CameraCaptureObserver <NSObject>

@optional
-(void)imageCaptured:(UIImage*)image;
-(void)caputureImageInfo:(CaputureImageInfo*)info;
// todo:add videoCaptured(Recorded)
-(void)activeFormatChanged:(CameraFormat)format;
-(void)currentSettingChanged:(CameraCurrentSetting)settings;

@end

@interface CameraCapture : NSObject

@property (nonatomic, weak) UIViewController* videoViewController;// ImagePicker関連
@property (nonatomic, weak) UIImageView* imageView;
@property (nonatomic) CGRect validRect;
//@property (nonatomic, retain) id<SignalDataUpdater> dataUpdater;
@property (nonatomic, weak) id<CameraCaptureObserver> cameraObserver;

+(CameraCapture*)getInstance;

-(void)setupCaptureDeviceWithSetting:(CameraSetting)settings;
-(void)changeCaptureDeviceSetup:(CameraSetting)settings;// input/output/session/connectionに分ける？
-(BOOL)changeActiveFormatWithIndex:(int)index;
-(void)changeFocusMode:(AVCaptureFocusMode)mode;
-(void)changeVideoZoom:(float)zoom withRate:(float)rate;
-(void)switchFPS:(float)fps;
-(void)changeExposureBias:(float)value;
-(NSString*)changeISO:(float)value;
-(float)changeExposureDuration:(float)value;
-(void)setFocusPoint:(CGPoint)point;
//-(void)setValidRect:(CGRect)rect;// NG.propertyのsetterなので、無限loopになる可能性がある。
-(void)startCapture;
-(void)stopCapture;
-(void)loadVideoFromPicker;

// todo:統一する
-(int)getVideoActiveFormatInFormats:(NSMutableArray*)formats;
-(CameraFormat)getVideoActiveFormatInfo;
-(CameraCurrentSetting)getCameraCurrentSettings;

@end
