//
//  AirCameraCapture.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AirCameraManager.h"
#import "FileManager.h"
#import "Log.h"

#define QUEUE_SERIAL_VIDEO_CAPTURE "com.threees.tre.led.video-capture"
#define QUEUE_SERIAL_SAMPLING "com.threees.tre.led.sampling"
#define QUEUE_SERIAL_SESSION "com.threees.tre.led.session"

static void *ExposureDurationContext = &ExposureDurationContext;
static void *ISOContext = &ISOContext;
static void *ExposureTargetOffsetContext = &ExposureTargetOffsetContext;

@class Log;

@implementation CaputureImageInfo

-(id)init
{
    if (self = [super init]) {
        _size = CGSizeZero;
    }
    
    return self;
}

@end

@interface CameraCapture()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// todo:strong??
@property (nonatomic, strong) AVCaptureSession* session;
@property (nonatomic, strong) AVCaptureDevice* videoDevice;
@property (nonatomic, strong) AVCaptureVideoDataOutput* videoOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput* movieOutput;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic) BOOL exposureCheanged;// 露出変更完了後キャプチャする
@property (nonatomic) CameraCurrentSetting currentSettings;
@property (nonatomic) BOOL record;

@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) dispatch_queue_t samplingQueue; // For sampling buffer of video captured.

-(void)setupCaptureDevice;
-(float)calculateExposureDurationSecond:(float)value;
-(float)calculateExposureDurationValue:(float)second;
-(void)setCameraCurrentSetting:(CameraSetting)settings;

@end

@implementation CameraCapture

@synthesize session;
@synthesize videoOutput;
@synthesize movieOutput;
@synthesize exposureCheanged;
@synthesize currentSettings;

@synthesize videoViewController;
@synthesize imageView;
@synthesize record;
@synthesize validRect;
//@synthesize dataUpdater;
@synthesize cameraObserver;


static float EXPOSURE_DURATION_POWER = 5; // Higher numbers will give the slider more sensitivity at shorter durations
static float EXPOSURE_MINIMUM_DURATION = 1.0/1000; // Limit exposure duration to a useful range
static int VIDEO_MAXIMUM_FRAME_RATE = 240;


static CameraCapture *sharedInstance = nil;

+(CameraCapture*)getInstance
{
    if (!sharedInstance) {
        sharedInstance = [CameraCapture new];
    }
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        self.record = NO;
        currentSettings.fps = 30;
    }
    
    return self;
}

- (void)eventHandler:(id)data
{
    DEBUGLOG(@"AVCaptureSession event : %@", [data name]);
}

-(float)calculateExposureDurationSecond:(float)value
{
    double p = pow( value, EXPOSURE_DURATION_POWER ); // Apply power function to expand slider's low-end range
    double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
    double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    double newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
    DEBUGLOG(@"durationSec(%f - %f)", minDurationSeconds, maxDurationSeconds);
    
    return (float)newDurationSeconds;
}

-(float)calculateExposureDurationValue:(float)second
{
    double minDurationSeconds = MAX(CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration), EXPOSURE_MINIMUM_DURATION);
    double maxDurationSeconds = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    // Map from duration to non-linear UI range 0-1
    double p = ( second - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds ); // Scale to 0-1
    double value = pow( p, 1 / EXPOSURE_DURATION_POWER ); // Apply inverse power
    
    return (float)value;
}

-(void)setCameraCurrentSetting:(CameraSetting)settings
{
    currentSettings.format = settings.format;
    currentSettings.fps = settings.fps;
    currentSettings.exposureValue = settings.exposureValue;
    currentSettings.exposureDuration = [self calculateExposureDurationSecond:settings.exposureValue];
    currentSettings.iso = settings.iso;
    currentSettings.bias = settings.bias;
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [self videoDevice];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            DEBUGLOG(@"%@", error);
        }
    });
}

-(void)addObservers
{
    [self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureDuration" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureDurationContext];
    [self addObserver:self forKeyPath:@"videoDeviceInput.device.ISO" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ISOContext];
    [self addObserver:self forKeyPath:@"videoDeviceInput.device.exposureTargetOffset" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:ExposureTargetOffsetContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDevice];
}

-(void)removeObservers
{
    [self removeObserver:self forKeyPath:@"videoDevice.exposureDuration" context:ExposureDurationContext];
    [self removeObserver:self forKeyPath:@"videoDevice.ISO" context:ISOContext];
    [self removeObserver:self forKeyPath:@"videoDevice.exposureTargetOffset" context:ExposureTargetOffsetContext];
}

// for auto mode
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ExposureDurationContext)
    {
        NSString *duration = nil;
        double newDurationSeconds = CMTimeGetSeconds([change[NSKeyValueChangeNewKey] CMTimeValue]);
        
        if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom) {
            double durationSeconds = [self calculateExposureDurationSecond:newDurationSeconds];
            // todo:別方法で返す
            if ( newDurationSeconds < 1 ) {
                int digits = MAX( 0, 2 + floor( log10( newDurationSeconds ) ) );
                duration = [NSString stringWithFormat:@"1/%.*f", digits, 1/newDurationSeconds];
            } else {
                duration = [NSString stringWithFormat:@"%.2f", newDurationSeconds];
            }
            
            // todo:return by observer method
        }
    }
    else if (context == ISOContext)
    {
        float newISO = [change[NSKeyValueChangeNewKey] floatValue];
        
        if (self.videoDevice.exposureMode != AVCaptureExposureModeCustom)
        {
            // todo:return by observer method
        }
    }
    else if (context == ExposureTargetOffsetContext)
    {
        float newExposureTargetOffset = [change[NSKeyValueChangeNewKey] floatValue];
        // todo:return by observer method
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

-(void)setupCaptureDevice
{
    // test
    self.record = NO;
    
    self.exposureCheanged = NO;
    
    // test
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        DEBUGLOG(@"Device name: %@", [device localizedName]);
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                DEBUGLOG(@"Device position : back");
            } else {
                DEBUGLOG(@"Device position : front");
            }
        }
    }
    
    dispatch_queue_t samplingQueue = dispatch_queue_create(QUEUE_SERIAL_SAMPLING, DISPATCH_QUEUE_SERIAL);
    [self setSamplingQueue:samplingQueue];
    
    //セッション作成
    self.session = [[AVCaptureSession alloc] init];
    
    
    // from AVCamManual
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
    
    dispatch_queue_t sessionQueue = dispatch_queue_create(QUEUE_SERIAL_SESSION, DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(self.sessionQueue, ^{// async:not blocked(context returned soon) for procsuring seral queue
        //デバイス取得
        self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (self.videoDevice != nil) {
            DEBUGLOG(@"AVCaptureDevice: %@", [self.videoDevice localizedName]);
            
            NSArray *events = [NSArray arrayWithObjects:
                               AVCaptureSessionRuntimeErrorNotification,
                               AVCaptureSessionErrorKey,
                               AVCaptureSessionDidStartRunningNotification,
                               AVCaptureSessionDidStopRunningNotification,
                               AVCaptureSessionWasInterruptedNotification,
                               AVCaptureSessionInterruptionEndedNotification,
                               nil];
            
            for (id e in events) {
                [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(eventHandler:)
                 name:e
                 object:session];
            }
            
            
#if 1
            // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
            //[self.session beginConfiguration];// nestしてもok.一番外側のcommit時設定される
            
            NSError *error = nil;
            
            if ([self.videoDevice lockForConfiguration:&error] == YES) {
                // 露出モード(シャッタスピード、ISO)設定
                // todo:fpsに影響が出るので、exposureDuration > (minFrameDuration=maxFrameDuration)にならないようにチェック
                if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                    self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
                }
                DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
                DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
                DEBUGLOG(@"exposureDuration: %f", CMTimeGetSeconds(self.videoDevice.exposureDuration));
                DEBUGLOG(@"bias: %f", self.videoDevice.exposureTargetBias);
                DEBUGLOG(@"offset: %f", self.videoDevice.exposureTargetOffset);
                
                // todo: foucus(とりあえず自動)
                if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                }
                DEBUGLOG(@"focusMode: %ld", self.videoDevice.focusMode);
                
                [self.videoDevice unlockForConfiguration];
            }
#else
            NSError *error = nil;
            AVCaptureDeviceFormat *selectedFormat = nil;
            //AVFrameRateRange *selectedFrameRateRange = nil;
            
            // todo:formatsからactiveFormatを選ぶ
            DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
            
            // @memo 先にactiveFormatを設定したほうが安全
            // 最大fps=240のformatを選択(420v/f?とりあえず、最初に見つかったformat)
            for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
                DEBUGLOG(@"format:%@", format);
                CMFormatDescriptionRef desc = format.formatDescription;
                // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得
                CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                //DEBUGLOG(@"format:%@ dimensions:(%d x %d)", format, dimensions.width, dimensions.height);
                
                for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                    DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                    // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                    if (range.maxFrameRate == VIDEO_MAXIMUM_FRAME_RATE) {
                        selectedFormat = format;
                        //selectedFrameRateRange = range;
                        break;
                    }
                }
                
                if (selectedFormat != nil) {
                    break;
                }
            }
            
            // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
            [self.session beginConfiguration];
            
            if ([self.videoDevice lockForConfiguration:&error] == YES) {
                // format/fps設定
                if (selectedFormat != nil) {
                    self.videoDevice.activeFormat = selectedFormat;
                    self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, self.cameraSettings.fps);
                    self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, self.cameraSettings.fps);
                }
                DEBUGLOG(@"minFrame:[%lld, %d, %d, %lld]", self.videoDevice.activeVideoMinFrameDuration.epoch, self.videoDevice.activeVideoMinFrameDuration.flags, self.videoDevice.activeVideoMinFrameDuration.timescale, self.videoDevice.activeVideoMinFrameDuration.value);
                DEBUGLOG(@"maxFrame:[%lld, %d, %d, %lld]", self.videoDevice.activeVideoMaxFrameDuration.epoch, self.videoDevice.activeVideoMaxFrameDuration.flags, self.videoDevice.activeVideoMaxFrameDuration.timescale, self.videoDevice.activeVideoMaxFrameDuration.value);
                DEBUGLOG(@"active format:%@", selectedFormat);
                
                // 露出モード(シャッタスピード、ISO)設定
                // todo:fpsに影響が出るので、exposureDuration > (minFrameDuration=maxFrameDuration)にならないようにチェック
                if ([self.videoDevice isExposureModeSupported:AVCaptureExposureModeCustom]) {
                    self.videoDevice.exposureMode = AVCaptureExposureModeCustom;
                    /* todo:前回設定値(configから)
                     DEBUGLOG(@"cameraSettings.exposureDuration: %f", self.cameraSettings.exposureDuration);
                     double exposureDuration = [self calculateExposureDurationSecond:self.cameraSettings.exposureDuration];
                     [self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(exposureDuration, 1000*1000*1000) ISO:AVCaptureISOCurrent completionHandler:^(CMTime syncTime) {
                     // todo:スレッドが違うので、方法検討
                     self.exposureCheanged = YES;
                     }];
                     */
                }
                DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
                DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
                
                // todo: foucus(とりあえず自動)
                if ([self.videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                    self.videoDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
                }
                DEBUGLOG(@"focusMode: %ld", self.videoDevice.focusMode);
                
                // zoomin
                //float zoomFactor = 1.0f;
                //float zoomRate = 1.0f;
                if ([self.videoDevice isRampingVideoZoom] == NO) {// zoom中ではない
                    // 最大光学zoom?
                    //self.videoDevice.videoZoomFactor = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
                    // 一定速度(rate)でzoom移動
                    //[device rampToVideoZoomFactor:zoomFactor withRate:zoomRate];
                    //[self.videoDevice unlockForConfiguration];
                }
                
                DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
                
                // test(照明)
                /*
                 if ([device hasTorch] == YES) {
                 if ([device isTorchModeSupported:AVCaptureTorchModeOn] == YES) {
                 device.torchMode = AVCaptureTorchModeOn;
                 [device unlockForConfiguration];
                 DEBUGLOG(@"AVCaptureTorchModeOn");
                 }
                 }
                 */
                
                DEBUGLOG(@"lensAperture: %f", self.videoDevice.lensAperture);
                
                [self.videoDevice unlockForConfiguration];
            }
#endif
            
            
            // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
            [self.session beginConfiguration];
            
            //入力作成
            //背面カメラ.AVCaptureDviceが無いiOSシミュレーターではdeviceがnil.落ちる
            AVCaptureDeviceInput* deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:NULL];
            if (deviceInput != nil) {
                if ([self.session canAddInput:deviceInput]) {
                    [self.session addInput:deviceInput];
                    DEBUGLOG(@"add input device");
                }
            }
            
            //ビデオデータ出力作成
            //AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
            if (videoOutput != nil) {
                if ([self.session canAddOutput:videoOutput]) {
                    [self.session addOutput:videoOutput];
                    DEBUGLOG(@"add output device");
                }
                
                NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
                //NSDictionary* settings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
                videoOutput.videoSettings = settings;
                //videoOutput.minFrameDuration = CMTimeMake(1, 15);//@memo 実際出力最小fps.deprecated (15fps) activeVideoMinFrameDurationで設定
                
                // ビデオ出力のキャプチャの画像情報のキューを設定(todo:終了時リリースdispatch_release(queue))
                //dispatch_queue_t queue = dispatch_queue_create("LEDQ", NULL);
                dispatch_queue_t queue = dispatch_queue_create(QUEUE_SERIAL_VIDEO_CAPTURE, DISPATCH_QUEUE_SERIAL);
                [videoOutput setSampleBufferDelegate:self queue:queue];
                //[videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
                
                // YES(default):場合によって、frameが処理されず破棄される可能性がある？
                // frameが破棄されると信号周期と同期が取れないので、とりあえずNOにして、破棄されないようにする(100%保証？)
                // todo:破棄される場合、callbackが呼ばれない？呼ばれない場合、fps(単位時間)で破棄されたかどうか(callbackの呼ばれた時間)の判断が必要かも
                //[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
                [videoOutput setAlwaysDiscardsLateVideoFrames:NO];
            }
            
            // ビデオファイル出力作成
            if (self.record == YES) {
                self.movieOutput = [[AVCaptureMovieFileOutput alloc] init];
                if (self.movieOutput != nil) {
                    if ([self.session canAddOutput:self.movieOutput]) {
                        [self.session addOutput:self.movieOutput];
                    }
                    
                    CMTime maxDuration = CMTimeMakeWithSeconds(60, 600);
                    self.movieOutput.maxRecordedDuration = maxDuration;
                    //self.movieOutput.minFreeDiskSpaceLimit = 500000000;
                }
            }
            
            AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
            if (videoConnection != nil) {
                // カメラの向きを設定する
                if ([videoConnection isVideoOrientationSupported])
                {
                    [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                    DEBUGLOG(@"AVCaptureVideoOrientationPortrait");
                }
                
                if ([videoConnection isEnabled] == NO) {
                    // outputDeviceで処理されるかどうかのフラグ?
                    videoConnection.enabled = YES;
                }
                DEBUGLOG(@"videoConnection.enabled: %d", videoConnection.enabled);
                
                //[videoConnection setVideoMinFrameDuration:CMTimeMake(1, 4)];//@memo 実際出力最小fps. deprecated 1/4(4fps) activeVideoMinFrameDurationで設定
                
                DEBUGLOG(@"videoMaxScaleAndCropFactor: %f", videoConnection.videoMaxScaleAndCropFactor);
                DEBUGLOG(@"videoScaleAndCropFactor: %f", videoConnection.videoScaleAndCropFactor);
            }
            
            // todo: パフォーマンスが落ちる場合、画質を調整
            if ([self.session canSetSessionPreset:AVCaptureSessionPresetMedium] == YES) {
                // @memo activeFormatと相互排他になるので、設定しない
                // todo:ただ、設定しないと、画像サイズが1920x1080になり、表示が拡大されて表示される！
                // inputDevice:1280x720->1920x1080(zoomin)->598x375(center-crop)
                // callbackで生データから表示サイズ588x375のImage作成？そもそも1920x1080で画像が拡大される...?
                // seesionPresetを設定しても、上で設定したactiveFormatが変わらない(outがinの範囲内から？)ので、とりあえず設定。
                self.session.sessionPreset = AVCaptureSessionPresetMedium;
                DEBUGLOG(@"AVCaptureSessionPresetMedium");
                
                //DEBUGLOG(@"active format:%@", selectedFormat);
                DEBUGLOG(@"exposureMode: %ld", self.videoDevice.exposureMode);
                DEBUGLOG(@"ISO: %f", self.videoDevice.ISO);
                DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
            }
            
            [self.session commitConfiguration];
            
            /* todo:未確認
             AVCaptureVideoPreviewLayer* videoLayer = (AVCaptureVideoPreviewLayer*)[AVCaptureVideoPreviewLayer layerWithSession:self.session];
             if (videoLayer != nil) {
             videoLayer.frame = self.videoViewController.view.bounds;
             videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
             [self.videoViewController.view.layer addSublayer:videoLayer];
             }
             */
            
            /*
             // カメラへのアクセス確認
             NSString *mediaType = AVMediaTypeVideo;
             [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
             if (granted)
             {
             //Granted access to mediaType
             [self setDeviceAuthorized:YES];
             }
             else {
             //Not granted access to mediaType
             dispatch_async(dispatch_get_main_queue(), ^{
             [[[UIAlertView alloc] initWithTitle:@"AVCam!"
             message:@"AVCam doesn't have permission to use Camera, please change privacy settings"
             ￼￼￼delegate:self
             cancelButtonTitle:@"OK"
             otherButtonTitles:nil] show];
             [self setDeviceAuthorized:NO];
             });
             }
             }];
             */
            
#if 0
            // UIを操作する場合、mainスレッドで行う
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.cameraObserver != nil) {
                    CameraFormat format = { 0 };
                    format.minExposureBias = self.videoDevice.minExposureTargetBias;
                    format.maxExposureBias = self.videoDevice.maxExposureTargetBias;
                    format.minISO = self.videoDevice.activeFormat.minISO;
                    format.maxISO = self.videoDevice.activeFormat.maxISO;
                    //format.minExposureDuration = self.videoDevice.activeFormat.minExposureDuration;
                    format.minFPS = 2;
                    for (AVFrameRateRange *range in self.videoDevice.activeFormat.videoSupportedFrameRateRanges) {
                        if (format.maxFPS < range.maxFrameRate) {
                            format.maxFPS = range.maxFrameRate;
                        }
                    }
                    
                    [self.cameraObserver activeFormatChanged:format];
                }
            });
#endif
            /*
             CameraCurrentSetting currentSettings;
             currentSettings.iso = self.videoDevice.ISO;
             currentSettings.bias = self.videoDevice.exposureTargetBias;
             [self.cameraObserver currentSettingChanged:currentSettings];
             */
        }
    });
    
    
}

-(void)setupCaptureDeviceWithSetting:(CameraSetting)settings
{
    // default setting
    [self setupCaptureDevice];
    
    // then change setup
    [self changeCaptureDeviceSetup:settings];
}

-(void)changeCaptureDeviceSetup:(CameraSetting)settings
{
    [self setCameraCurrentSetting:settings];
    
    // current settings may be changed when active format was changed.
    [self changeActiveFormatWithIndex:currentSettings.format];
    //[self changeExposureDuration:currentSettings.exposureValue];
    //[self changeISO:currentSettings.iso];
    //[self changeExposureBias:currentSettings.bias];
    //[self switchFPS:currentSettings.fps];
    
    //[self changeFocusMode:AVCaptureFocusModeAutoFocus];// auto
    //[self changeVideoZoom:<#(float)#> withRate:<#(float)#>];// none
}

-(BOOL)changeActiveFormatWithIndex:(int)index
{
    __block BOOL ret = NO;
    
    dispatch_async(self.sessionQueue, ^{
        if (self.videoDevice != nil) {
            NSError *error = nil;
            for (int i = 0; i < [[self.videoDevice formats] count]; i++) {
                // todo:check format and current settings
                if (i == index) {
                    CameraCurrentSetting activeSettings = currentSettings;
                    AVCaptureDeviceFormat *format = (AVCaptureDeviceFormat*)[[self.videoDevice formats] objectAtIndex:index];
                    DEBUGLOG(@"format:%@", format);
                    CMFormatDescriptionRef desc = format.formatDescription;
                    // AVCaptureDeviceFormatに映像サイズがないので(静止サイズはある)、下記の方法で取得
                    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
                    //DEBUGLOG(@"format:%@ dimensions:(%d x %d)", format, dimensions.width, dimensions.height);
                    
                    float currentFps = activeSettings.fps;
                    // 実際1rangeしかない?
                    for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                        DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                        // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                        
                        // 範囲内にあるまでloop。ない場合、最後のrangeの最小/最大値を取る
                        currentFps = currentSettings.fps;
                        if (currentFps < range.minFrameRate) {
                            currentFps = range.minFrameRate;
                        } else if (currentFps > range.maxFrameRate) {
                            currentFps = range.maxFrameRate;
                        } else {
                            break;
                        }
                    }
                    activeSettings.fps = currentFps;
                    
                    // check ISO
                    if (currentSettings.iso < self.videoDevice.activeFormat.minISO) {
                        activeSettings.iso = self.videoDevice.activeFormat.minISO;
                    } else if (currentSettings.iso > self.videoDevice.activeFormat.maxISO) {
                        activeSettings.iso = self.videoDevice.activeFormat.maxISO;
                    }
                    
                    // check Bias
                    if (currentSettings.bias < self.videoDevice.minExposureTargetBias) {
                        activeSettings.bias = self.videoDevice.minExposureTargetBias;
                    } else if (currentSettings.bias > self.videoDevice.maxExposureTargetBias) {
                        activeSettings.bias = self.videoDevice.maxExposureTargetBias;
                    }
                    
                    // check exposureDuration
                    //float minValue = [self calculateExposureDurationValue:CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration)];
                    //float maxValue = [self calculateExposureDurationValue:CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration)];
                    // the range is 0-1
                    float minValue = 0.0;
                    float maxValue = 1.0;
                    if (currentSettings.exposureValue < minValue) {
                        activeSettings.exposureValue = minValue;
                    } else if (currentSettings.exposureValue > maxValue) {
                        activeSettings.exposureValue = maxValue;
                    }
                    //activeSettings.exposureDuration = [self calculateExposureDurationSecond:activeSettings.exposureValue];
                    
                    // todo:範囲を最小限にする? activeFormatとmin/maxDurationは同時に設定する必要がある。
                    [self.session beginConfiguration];
                    if ([self.videoDevice lockForConfiguration:&error]) {
                        self.videoDevice.activeFormat = format;
                        //self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, currentSettings.fps);
                        //self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, currentSettings.fps);
                        [self.videoDevice unlockForConfiguration];
                        
                        currentSettings.format = index;
                    }
                    
                    [self changeExposureDuration:activeSettings.exposureValue];
                    [self changeISO:activeSettings.iso];
                    [self changeExposureBias:activeSettings.bias];
                    [self switchFPS:activeSettings.fps];
                    
                    [self.session commitConfiguration];
                    
                    // activeFormatが変わった場合、format情報変更通知(plist更新/debug画面更新など)
                    if (self.cameraObserver != nil) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            CameraFormat format = [self getVideoActiveFormatInfo];
                            [self.cameraObserver activeFormatChanged:format];
                            
                            //CameraCurrentSetting currentSettings = [self getCameraCurrentSettings];
                            [self.cameraObserver currentSettingChanged:currentSettings];
                        });
                    }
                    
                    //return YES;
                    ret = YES;
                    break;
                }
            }
        }
    });
    
    return ret;
}

-(void)changeFocusMode:(AVCaptureFocusMode)mode
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        // todo: foucus(とりあえず自動)
        if ([self.videoDevice isFocusModeSupported:mode]) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                self.videoDevice.focusMode = mode;
                [self.videoDevice unlockForConfiguration];
            }
        }
        
        DEBUGLOG(@"focusMode: %ld", (long)self.videoDevice.focusMode);
    }
}

-(void)changeVideoZoom:(float)zoom withRate:(float)rate
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        if ([self.videoDevice isRampingVideoZoom] == NO) {// zoom中ではない
            if ([self.videoDevice lockForConfiguration:&error]) {
                // 最大光学zoom?
                //self.videoDevice.videoZoomFactor = self.videoDevice.activeFormat.videoZoomFactorUpscaleThreshold;
                // 一定速度(rate)でzoom移動
                [self.videoDevice rampToVideoZoomFactor:zoom withRate:rate];
                [self.videoDevice unlockForConfiguration];
            }
        }
        
        DEBUGLOG(@"videoZoomFactor: %f", self.videoDevice.videoZoomFactor);
    }
}

// todo:check range
// AVCaptureExposureModeCustomの場合、exposureTargetOffsetに影響があるが、全体露出に影響がない(duration/ISOを自動変更できないので)
-(void)changeExposureBias:(float)value
{
    NSError *error = nil;
    
    if (self.videoDevice != nil) {
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                [self.videoDevice setExposureTargetBias:value completionHandler:nil];
                DEBUGLOG(@"exposureTargetBias: %f changed.", self.videoDevice.exposureTargetBias);
                [self.videoDevice unlockForConfiguration];
                currentSettings.bias = value;
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
}

// todo:check range
-(NSString*)changeISO:(float)value
{
    NSError *error = nil;
    NSString *strISO = nil;
    
    if (self.videoDevice != nil) {
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            //float isoValue = self.videoDevice.activeFormat.minISO + (self.videoDevice.activeFormat.maxISO - self.videoDevice.activeFormat.minISO) * value;
            if ([self.videoDevice lockForConfiguration:&error]) {
                [self.videoDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:value completionHandler:nil];
                DEBUGLOG(@"ISO: %f changed.", self.videoDevice.ISO);
                [self.videoDevice unlockForConfiguration];
                currentSettings.iso = value;
                strISO = [NSString stringWithFormat:@"ISO: %f changed.", self.videoDevice.ISO];
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
    
    return strISO;
}

// todo:check range
// 0の場合、変更なしと判断(duration/ISOは正数になっているが、biasは?todo:調査)
-(float)changeExposureDuration:(float)value
{
    NSError *error = nil;
    float durationSeconds = -1;
    
    if (self.videoDevice != nil) {
        //DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        
        durationSeconds = [self calculateExposureDurationSecond:value];
        
        if (self.videoDevice.exposureMode == AVCaptureExposureModeCustom) {
            if ([self.videoDevice lockForConfiguration:&error]) {
                [self.videoDevice setExposureModeCustomWithDuration:CMTimeMakeWithSeconds(durationSeconds, 1000*1000*1000) ISO:AVCaptureISOCurrent completionHandler:nil];
                DEBUGLOG(@"exposureDuration: %f changed.", durationSeconds);
                [self.videoDevice unlockForConfiguration];
                currentSettings.exposureValue = value;
                currentSettings.exposureDuration = durationSeconds;
                
                // todo:別方法で返す
                /*
                 if ( durationSeconds < 1 ) {
                 int digits = MAX( 0, 2 + floor( log10( durationSeconds ) ) );
                 DEBUGLOG(@"digits:%d", digits);
                 duration = [NSString stringWithFormat:@"1/%.*f", digits, 1/durationSeconds];
                 DEBUGLOG(@"duration:%@", duration);
                 } else {
                 duration = [NSString stringWithFormat:@"%.2f", durationSeconds];
                 }*/
            } else {
                DEBUGLOG(@"%@", error);
            }
        }
    }
    
    return durationSeconds;
}

// todo:check range
-(void)switchFPS:(float)fps
{
    // sessionの設定などがないので、わざわざ停止する必要はない？
    //if (self.session.isRunning) {
    //    [self.session stopRunning];
    //}
    
    //AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (self.videoDevice != nil) {
        DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        //CGFloat fps = strFPS.doubleValue;
#if true
        // todo:シャッタースピードに影響が出る可能性があるば、fps優先なので、問題無い。ただ、SSが変わった時、通知/表示?する
        if ([self.videoDevice lockForConfiguration:nil]) {
            self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)fps);
            self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)fps);
            [self.videoDevice unlockForConfiguration];
            currentSettings.fps = fps;
        }
#else
        AVCaptureDeviceFormat *selectedFormat = nil;
        int32_t maxWidth = 0;
        AVFrameRateRange *frameRateRange = nil;
        
        for (AVCaptureDeviceFormat *format in [self.videoDevice formats]) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            
            for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
                DEBUGLOG(@"frame[%f, %f] demensions[%d, %d]", range.minFrameRate, range.maxFrameRate, dimensions.width, dimensions.height);
                // todo:widthについて再検討。最大解像度になっている。画像が拡大されている。切出し？zoom?
                if (range.minFrameRate <= fps && fps <= range.maxFrameRate && dimensions.width >= maxWidth) {
                    selectedFormat = format;
                    frameRateRange = range;
                    maxWidth = dimensions.width;
                }
            }
        }
        
        if (selectedFormat) {
            
            // activeFormatとmin/maxDurationは同時に設定する必要がある。
            [self.session beginConfiguration];
            
            if ([self.videoDevice lockForConfiguration:nil]) {
                
                // <AVCaptureDeviceFormat: 0x174018180 'vide'/'420f' 3264x2448, { 2- 30 fps}, HRSI:3264x2448, fov:58.040, max zoom:153.00 (upscales @1.00), AF System:2, ISO:29.0-1856.0, SS:0.000013-0.500000>
                DEBUGLOG(@"selected format:%@", selectedFormat);
                self.videoDevice.activeFormat = selectedFormat;
                self.videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)fps);
                self.videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)fps);
                [self.videoDevice unlockForConfiguration];
            }
            
            [self.session commitConfiguration];
        }
#endif
        
        //if (!self.session.isRunning) {
        //    [self.session startRunning];
        //}
    }
}

-(void)setFocusPoint:(CGPoint)point
{
    //AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (self.videoDevice != nil) {
        DEBUGLOG(@"active format:%@", self.videoDevice.activeFormat);
        if (self.videoDevice.isFocusPointOfInterestSupported) {
            if ([self.videoDevice lockForConfiguration:nil]) {
                [self.videoDevice setFocusPointOfInterest:point];
                [self.videoDevice unlockForConfiguration];
            }
        }
    }
}

-(void)startCapture
{
    [Log debug:@"startCapture..."];
    
    dispatch_async([self sessionQueue], ^{
        // セッションを開始
        if (self.session.running == NO) {
            [self.session startRunning];
            
            if (self.record == YES) {
                NSDateFormatter* df = [[NSDateFormatter alloc] init];
                [df setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];
                NSDate *now = [NSDate date];
                NSString *strNow = [df stringFromDate:now];
                NSURL* fileURL = [FileManager getURLWithFileName:[NSString stringWithFormat:@"movie_%@.mov", strNow]];
                if (fileURL != nil) {
                    [self.movieOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
                }
            }
            
            
            [Log debug:@"startRunning..."];
        }
    });
}

-(void)stopCapture
{
    [Log debug:@"stopCapture..."];
    
    dispatch_async([self sessionQueue], ^{
        // セッションを停止
        if (self.session.running == YES) {
            if (self.record == YES) {
                [self.movieOutput stopRecording];
            }
            [self.session stopRunning];
            [Log debug:@"stopRunning."];
        }
    });
}

-(int)getVideoActiveFormatInFormats:(NSMutableArray*)formats
{
    int index = 0;
    //formats = [[NSMutableArray alloc] init];
    
    if (self.videoDevice != nil && formats != nil) {
        for (int i = 0; i < [[self.videoDevice formats] count]; i++) {
            AVCaptureDeviceFormat *format = (AVCaptureDeviceFormat*)[[self.videoDevice formats] objectAtIndex:i];
            [formats addObject:[NSString stringWithFormat:@"%@", format]];
            //if (self.videoDevice.activeFormat == format) {
            //    index = i;
            //}
        }
        
        index = currentSettings.format;
    }
    
    return index;
}

-(CameraFormat)getVideoActiveFormatInfo
{
    CameraFormat format = { 0 };
    format.minExposureBias = self.videoDevice.minExposureTargetBias;
    format.maxExposureBias = self.videoDevice.maxExposureTargetBias;
    format.minISO = self.videoDevice.activeFormat.minISO;
    format.maxISO = self.videoDevice.activeFormat.maxISO;
    format.minExposureValue = 0.0;
    format.maxExposureValue = 1.0;
    format.minExposureDuration = CMTimeGetSeconds(self.videoDevice.activeFormat.minExposureDuration);
    format.maxExposureDuration = CMTimeGetSeconds(self.videoDevice.activeFormat.maxExposureDuration);
    format.minFPS = 2;
    for (AVFrameRateRange *range in self.videoDevice.activeFormat.videoSupportedFrameRateRanges) {
        if (format.maxFPS < range.maxFrameRate) {
            format.maxFPS = range.maxFrameRate;
            format.minFPS = range.minFrameRate;
        }
    }
    
    return format;
}

-(CameraCurrentSetting)getCameraCurrentSettings
{
    return currentSettings;
}


- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error {
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    if (recordedSuccessfully == YES) {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:nil];
    }
}


//delegateメソッド。各フレームにおける処理(LEDQキューからフレーム順に呼ばれる)
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //[Log debug:(@"@@captureOutput called.")];
    
    /*
     DEBUGLOG(@"<<*********************>>");
     CMItemCount num = CMSampleBufferGetNumSamples(sampleBuffer);
     DEBUGLOG(@"num:%ld", num);
     
     CMTime duration = CMSampleBufferGetDuration(sampleBuffer);
     DEBUGLOG(@"duration:%lld", duration.value);
     DEBUGLOG(@"duration:%lld", duration.value / duration.timescale);
     DEBUGLOG(@"duration:%f", (float)duration.value / duration.timescale);
     DEBUGLOG(@"duration:%fs", CMTimeGetSeconds(duration));
     
     CMTime presTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
     DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value);
     DEBUGLOG(@"presTimestamp:%lld", presTimestamp.value / presTimestamp.timescale);
     DEBUGLOG(@"presTimestamp:%f", (float)presTimestamp.value / presTimestamp.timescale);
     DEBUGLOG(@"presTimestamp:%fs", CMTimeGetSeconds(presTimestamp));
     
     CMTime decodeTimestamp = CMSampleBufferGetDecodeTimeStamp(sampleBuffer);
     DEBUGLOG(@"decodeTimestamp:%lld", decodeTimestamp.value);
     DEBUGLOG(@"decodeTimestamp:%lld", decodeTimestamp.value / decodeTimestamp.timescale);
     DEBUGLOG(@"decodeTimestamp:%f", (float)decodeTimestamp.value / decodeTimestamp.timescale);
     DEBUGLOG(@"decodeTimestamp:%fs", CMTimeGetSeconds(decodeTimestamp));
     
     CMTime outputDuration = CMSampleBufferGetOutputDuration(sampleBuffer);
     DEBUGLOG(@"outputDuration:%lld", outputDuration.value);
     DEBUGLOG(@"outputDuration:%lld", outputDuration.value / outputDuration.timescale);
     DEBUGLOG(@"outputDuration:%f", (float)outputDuration.value / outputDuration.timescale);
     DEBUGLOG(@"outputDuration:%fs", CMTimeGetSeconds(outputDuration));
     
     CMTime outputPresTimestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
     DEBUGLOG(@"outputPresTimestamp:%lld", outputPresTimestamp.value);
     DEBUGLOG(@"outputPresTimestamp:%lld", outputPresTimestamp.value / outputPresTimestamp.timescale);
     DEBUGLOG(@"outputPresTimestamp:%f", (float)outputPresTimestamp.value / outputPresTimestamp.timescale);
     DEBUGLOG(@"outputPresTimestamp:%fs", CMTimeGetSeconds(outputPresTimestamp));
     
     CMTime outputDecodeTimestamp = CMSampleBufferGetOutputDecodeTimeStamp(sampleBuffer);
     DEBUGLOG(@"outputDecodeTimestamp:%lld", outputDecodeTimestamp.value);
     DEBUGLOG(@"outputDecodeTimestamp:%lld", outputDecodeTimestamp.value / outputDecodeTimestamp.timescale);
     DEBUGLOG(@"outputDecodeTimestamp:%f", (float)outputDecodeTimestamp.value / outputDecodeTimestamp.timescale);
     DEBUGLOG(@"outputDecodeTimestamp:%fs", CMTimeGetSeconds(outputDecodeTimestamp));
     
     size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
     DEBUGLOG(@"size:%ld", size);
     DEBUGLOG(@"<<*********************>>");
     */
    
    // 画像の取得 todo:UIImageに変換する必要がある？SWに渡す最適な画像形式について検討。
    // @todo:ここから非同期シリアルキューにする？処理が遅い場合、キューに溜めるので、メモリ増えるかも。frameがdropされるより良いかも？
    CaputureImageInfo *info = [self imageFromSampleBufferRef:sampleBuffer];
    self.image = info.image;
    //[self.cameraObserver imageCaptured:self.image];
    [self.cameraObserver caputureImageInfo:info];
    
    
    
#if false // 無効。CaptureViewControllerに画像を返して解析
    
#if false
    // 落ちる！todo:Layerで検討してみる。or 表示画面を切り出し部分にする（それ以外の部分表示しない）？
    
    // 指定範囲の画像を切り出し
#if false
    float scale = [[UIScreen mainScreen] scale];
    CGRect scaledRect = CGRectMake(self.validRect.origin.x * scale,
                                   self.validRect.origin.y * scale,
                                   self.validRect.size.width * scale,
                                   self.validRect.size.height * scale);
    
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, scaledRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef
                                               scale:scale
                                         orientation:UIImageOrientationUp];
#else
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, self.validRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef];
#endif
    
    
    // LED信号機検出
    NSMutableArray* signals = [NSMutableArray array];
    UIImage* ledImage = [SmartEyeW detectSignal:clipedImage signals:signals];
    //    [Log debug:(@"@@detectSignal called.")];
    
    // 合成
    UIGraphicsBeginImageContext(self.imageView.bounds.size);
    [self.image drawInRect:self.imageView.bounds];
    [ledImage drawInRect:self.validRect];
    UIImage *compImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
#else
    
    // LED信号機検出
    // todo:メモリが増えて落ちるな。
    CGImageRef clipImageRef = CGImageCreateWithImageInRect(self.image.CGImage, self.validRect);
    UIImage *clipedImage = [UIImage imageWithCGImage:clipImageRef];
    NSMutableArray* signals = [NSMutableArray array];
    UIImage* ledImage = [SmartEyeW detectSignal:clipedImage signals:signals];
    //    [Log debug:(@"@@detectSignal called.")];
    
    // todo:ここで解放OK?
    CGImageRelease(clipImageRef);
#endif
    
#if false
    // 必要であれば、画像をphotoに保存
    ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
    //[library writeImageToSavedPhotosAlbum
#endif
    
#if true
    // 画像を画面に表示
    //dispatch_async(dispatch_get_main_queue(), ^{// 別スレッド
    dispatch_sync(dispatch_get_main_queue(), ^{// 現スレッド(ログ見ると別スレッドになっている？！両方ともメインスレッド？)
        if (ledImage != nil) {
            //if (self.image != nil) {
            //self.imageView.image = self.image;
            //self.imageView.image = clipedImage;
            //self.imageView.image = ledImage;
            //self.imageView.image = compImage;
            //[Log debug:(@"@@set image.")];
            // graphデータ更新
            //[self.dataUpdater signalGraphData:signals];
            [self.dataUpdater signalGraphData:signals detectedImage:ledImage captureImage:clipedImage];
        } else {
            [Log debug:(@"@@ledImage is nil.")];
        }
    });
#endif
    
    
#endif
    
}

// CMSampleBufferRefをUIImageへ
- (CaputureImageInfo*)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
    // この処理時間大体0.001s
    //[Log debug:@"==== CMSampleBufferRef to UIImage start ===="];
    CaputureImageInfo *imageInfo = [[CaputureImageInfo alloc] init];
    // イメージバッファの取得
    CVImageBufferRef    buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // イメージバッファのロック
    CVPixelBufferLockBaseAddress(buffer, 0);
    // イメージバッファ情報の取得
    uint8_t*    base;
    size_t      width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    //DEBUGLOG(@"witdh:%zu height:%zu", width, height);
    
    // ビットマップコンテキストの作成
    CGColorSpaceRef colorSpace;
    CGContextRef    cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(
                                      base, width, height, 8, bytesPerRow, colorSpace,
                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    // 画像の作成
    CGImageRef  cgImage;
    UIImage*    image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage scale:1.0f
                          orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    // イメージバッファのアンロック
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    imageInfo.image = image;
    imageInfo.size = CGSizeMake(width, height);
    imageInfo.timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    //[Log debug:@"==== CMSampleBufferRef to UIImage end ===="];
    
    return imageInfo;
}



// ImagePickerのObjective-c版(Swift版である程度確認済。リアルタイム検出NG)
-(void)loadVideoFromPicker
{
    // カメラが利用できるか確認
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        // カメラかライブラリからの読み込み指定。カメラを指定
        [imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
        
        // MobileCoreServicesヘッダ必要。
        //[imagePickerController setMediaTypes:[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil]];
        
        // トリミングなどを行うか否か
        [imagePickerController setAllowsEditing:NO];
        // Delegateをセット
        [imagePickerController setDelegate:self];
        
        // アニメーションをしてカメラUIを起動(todo 上記設定処理と分離)
        [self.videoViewController presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // 撮影画像(1枚のみ??)を取得
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    // 撮影した写真をUIImageViewへ設定
    self.imageView.image = originalImage;
    
#if false
    // 検出器生成
    NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:options];
    
    // 検出
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:originalImage.CGImage];
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:6] forKey:CIDetectorImageOrientation];
    NSArray *array = [detector featuresInImage:ciImage options:imageOptions];
    
    // 検出されたデータを取得
    for (CIRectangleFeature *rectFeature in array) {
        // todo LED信号機
    }
#endif
    
    // カメラUIを閉じる
    [self.videoViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
