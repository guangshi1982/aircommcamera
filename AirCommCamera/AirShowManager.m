//
//  AirShowCreator.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AirShowManager.h"
#import "FileManager.h"

#define kVideoFPS   24

#define AIR_FOLDER_TMP "airfolder/tmp"

/* need private method only
@protocol AssetWriterObserver <NSObject>

@optional
-(void)writeCompleted;

@end

@interface AirShowManager() <AssetWriterObserver>
 */

typedef enum {
    AirShowProcessNone = 0,
    AirShowProcessMovie,
    AirShowProcessSound,
} AirShowProcess;

@interface AirShowManager()

@property (nonatomic, strong) AVAssetWriter* videoWriter;

//@property (nonatomic, copy) NSString *soundPath;
@property (nonatomic, copy) NSString* movPath;
//@property (nonatomic, copy) NSString *showPath;
//@property (nonatomic, weak) id<AssetWriterObserver> writerObserber;

@property (nonatomic, copy) NSString* movieFolder;
@property (nonatomic) NSArray* airImages;
@property (nonatomic) int movieCount;

@end

@implementation AirShowManager

+(AirShowManager*)getInstance
{
    static AirShowManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AirShowManager new];
    });
    
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        /*[FileManager deleteSubFolder:@"airfolder/tmp"];
        [FileManager createSubFolder:@"airfolder/tmp"];
        [FileManager createSubFolder:@"airfolder/tmp/airimage"];
        [FileManager createSubFolder:@"airfolder/tmp/airmovie"];
        [FileManager createSubFolder:@"airfolder/tmp/airshow"];*/
//        _movPath = [FileManager getPathWithFileName:@"tmp.mov" fromFolder:@"/airmovie"];
        //_writerObserber = self;
    }
    
    return self;
}

- (void)createAirMovieWithAirImage:(AirImage*)airImage movie:(NSString*)moviePath
{
    if (airImage != nil && moviePath != nil) {
        //moviePath = [FileManager getPathWithFileName:[NSString stringWithFormat:@"tmp%d.mov", 1] fromFolder:@"/airmovie"];
        [self writeImageToMovie:airImage.image toPath:moviePath];
    }
}

- (void)createAirMoviesWithAirImages:(NSArray*)airImages movies:(NSString*)movieFolder
{
    if (airImages != nil && movieFolder != nil) {
        _movieFolder = movieFolder;
        _airImages = airImages;
        _movieCount = 0;
        
        if (_movieCount < [_airImages count]) {
            [self startCreateMovie];
        }
    }
}

- (void)connectAirMovies:(NSArray*)airMovies movie:(NSString*)moviePath
{
    if (airMovies != nil && moviePath != nil) {
        //NSString *moviePath = [FileManager getPathWithFileName:@"airmovie.mov" fromFolder:@"/airfolder/tmp/airmovie/connection"];
        NSMutableArray *movieList = [[NSMutableArray alloc] init];
        for (int i = 0; i < [airMovies count]; i++) {
            AirMovie *airMovie = [airMovies objectAtIndex:i];
            if (airMovie != nil) {
                [movieList addObject:airMovie.filePath];
            }
        }
        
        [self connectMovies:movieList movie:moviePath];
    }
}

- (void)createAirShowFromAirMovie:(AirMovie*)airMovie withAirSound:(AirSound*)airSound show:(NSString*)showPath;
{
    if (airMovie != nil && airSound != nil && showPath != nil) {
        //NSString *moviePath = [FileManager getPathWithFileName:@"airsound.mov" fromFolder:@"/airfolder/tmp/airsound/before"];
        [self addSoundToMovie:airMovie.filePath sound:airSound.filePath show:showPath];
    }
}

// create with images automatically
- (void)createShowWithAirImages:(NSArray*)airImages
{
    
}

/*
- (void)setSoundPath:(NSString*)soundPath showPath:(NSString*)showPath
{
    _soundPath = soundPath;
    _showPath = showPath;
    _movPath = [FileManager getPathWithFileName:@"tmp.mov" fromFolder:@"/airmovie"];
}
 */
 

// todo:set image size?
- (UIImage*)thumbnailOfVideo:(NSString*)videoPath
{
    NSLog(@"thumbnailOfVideo start");
    
    NSURL *videoUrl = [NSURL fileURLWithPath:videoPath];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    //Float64 durationSeconds = CMTimeGetSeconds([asset duration]);
    CMTime firstpoint = CMTimeMakeWithSeconds(0, 600);
    NSError *error;
    CMTime actualTime;
    CGImageRef firstImage = [imageGenerator copyCGImageAtTime:firstpoint
                                                     actualTime:&actualTime error:&error];
    
    UIImage *thumnail = [UIImage imageWithCGImage:firstImage];
    CGImageRelease(firstImage);
    
    NSLog(@"thumbnailOfVideo end");
    
    return thumnail;
}

- (void)createSlideShowWithImages:(NSArray *)images sound:(NSString*)soundPath show:(NSString*)showPath
{
    if (images != nil && soundPath != nil && showPath != nil) {
#if true
        // todo:シリアルキューで順番に複数動画を作成(非同期で作成するので、キューを使わないと、一部正常に生成されない。。。)
        NSMutableArray *moviePathList = [[NSMutableArray alloc] init];
        for (int i = 0; i < images.count; i++) {
            NSString *moviePath = [FileManager getPathWithFileName:[NSString stringWithFormat:@"tmp%d.mov", i] fromFolder:@"airfolder/tmp/airmovie"];
            [self writeImageToMovie:images[i] toPath:moviePath];
            [moviePathList addObject:moviePath];
        }
#endif
        
#if false // create show from animation(created with images) and sound
        // animation layer seems to be ok. need base video for adding the layer??
        CALayer *layer = [self animationLayerWithImages:images];
        [self createSlideShowWithAnimationLayer:layer sound:soundPath show:showPath];
#endif
        
#if false // create show from images and sound
        //[self writeImagesAsMovie:images toPath:_movPath];// OK
        // 上記は非同期で作成しているので、作成完了後下記を呼び出す必要がある
        //[self animateMovie:_movPath frameCount:(int)images.count timeOfFrame:3 show:showPath];
        NSString *movPath = [[NSBundle mainBundle] pathForResource:@"1" ofType:@".mov"];
        [self animateMovie:movPath frameCount:(int)images.count timeOfFrame:3 show:showPath];
        
        if (soundPath != nil) {
         //   [self addSoundToMovie:_movPath sound:soundPath show:showPath];
        } else {
            // todo:copy movie to show.
        }
#endif
    }
}


- (void)startCreateMovie
{
    NSLog(@"startCreateMovie");
    
    AirImage *airImage = (AirImage*)_airImages[_movieCount];
    NSString *moviePath = [FileManager getPathWithFileName:[NSString stringWithFormat: @"%@.mov", airImage.fileName] fromFolder:_movieFolder];
    
    if (airImage != nil && moviePath != nil) {
        [self writeImageToMovie:airImage.image toPath:moviePath];
    }
}

- (void)writeMovieCompleted:(NSString*)moviePath
{
    NSLog(@"writeCompleted:[%d]", _movieCount);
    
    if (_observer != nil) {
        float progress = (float)(_movieCount + 1) / [_airImages count];
        [_observer progress:progress * 100 inCreatingMovies:_movieFolder];
    }
    
    _movieCount++;
    if (_movieCount < [_airImages count]) {
        [self startCreateMovie];
    }
}

- (void)makeAirShowNextProcess:(AirShowProcess)process
{
    
}

- (void)createSlideShowWithAnimationLayer:(CALayer*)animationLayer sound:(NSString*)soundPath show:(NSString*)showPath
{
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    NSLog(@"animationLayer.frame:[%f, %f]", animationLayer.frame.size.width, animationLayer.frame.size.height);
    parentLayer.frame = animationLayer.frame;
    videoLayer.frame = animationLayer.frame;
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:animationLayer];
    
    CAAnimation *animation = [animationLayer animationForKey:@"airshow"];
    CMTime endTime = CMTimeMake(animation.duration * kVideoFPS, kVideoFPS);
    CMTimeRange duration = CMTimeRangeMake(kCMTimeZero, endTime);
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error;
    
    // audio
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    AVURLAsset *soundAsset = [[AVURLAsset alloc] initWithURL:soundURL options:nil];
    AVAssetTrack *soundTrack = [soundAsset tracksWithMediaType:AVMediaTypeAudio][0];
    AVMutableCompositionTrack *compositionSoundTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTimeRange soundRange = duration;
    [compositionSoundTrack insertTimeRange:soundRange ofTrack:soundTrack atTime:kCMTimeZero error:&error];
    
    // video
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    AVMutableVideoCompositionInstruction *videoInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoInstruction.timeRange = duration;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = animationLayer.frame.size;
    videoComposition.instructions = @[videoInstruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                      videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                      inLayer:parentLayer];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:showPath])
    {
        [fm removeItemAtPath:showPath error:&error];
    }
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:showPath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

// 複数のimageから作成したアニメのlayerを返す
- (CALayer*)animationLayerWithImages:(NSArray*)images
{
    CALayer *layer = [CALayer layer];
    // 最初の画像から動画のサイズ指定する
    UIImage *img = (UIImage*)[images objectAtIndex:0];
    CGSize size = img.size;
    layer.frame = CGRectMake(0, 0, size.width, size.height);
    NSLog(@"layer:%@", layer);
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    int imageCount = (int)images.count;
    float imageTime = 2.0f;
    
    CAKeyframeAnimation *animationContents = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
    animationContents.duration = imageTime * imageCount;
    
    NSMutableArray *keyTimes = [[NSMutableArray alloc] init];
    [keyTimes addObject:[NSNumber numberWithFloat:0.0]];
    for (int i = 0; i < imageCount; i++) {
        NSNumber *keyTime = [NSNumber numberWithFloat:((float)i / (imageCount - 1))];
        NSLog(@"keyTime:%@", keyTime);
        [keyTimes addObject:keyTime];
    }
    animationContents.keyTimes = keyTimes;
    
    NSMutableArray *values = [[NSMutableArray alloc] init];
    for (int i = 0; i < imageCount; i++) {
        UIImage *image = (UIImage*)[images objectAtIndex:i];
        [values addObject:(id)image.CGImage];
    }
    animationContents.values = values;
    
    group.animations = [NSArray arrayWithObjects:animationContents, nil];
    
    [layer addAnimation:group forKey:@"airshow"];
    
    return layer;
}

// 画像から動画作成(音声なし/横モードに調整)
- (void)writeImageToMovie:(UIImage*)image toPath:(NSString*)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 既にファイルがある場合は削除する
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    
    // 最初の画像から動画のサイズ指定する
    CGSize size = image.size;
    
    NSError *error = nil;
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    NSDictionary *outputSettings =
    @{
      AVVideoCodecKey  : AVVideoCodecH264,
      AVVideoWidthKey  : @(size.width),
      AVVideoHeightKey : @(size.height),
      };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:outputSettings];
    //writerInput.transform
    
    if ([self.videoWriter canAddInput:writerInput]) {
        [self.videoWriter addInput:writerInput];
    }
    
#if true
    NSDictionary *sourcePixelBufferAttributes =
    @{
      (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB),
      (NSString *)kCVPixelBufferWidthKey           : @(size.width),
      (NSString *)kCVPixelBufferHeightKey          : @(size.height),
      };
#else
    NSDictionary *sourcePixelBufferAttributes =
    @{
      (NSString *)kCVPixelBufferCGImageCompatibilityKey : [NSNumber numberWithBool:YES],
      (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey : [NSNumber numberWithBool:YES],
      (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32ARGB]};
#endif
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    writerInput.expectsMediaDataInRealTime = YES;
    
    // 生成開始できるか確認
    if (![self.videoWriter startWriting]) {
        NSLog(@"Failed to start writing.");
        return;
    }
    
    // 動画生成開始
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // pixel bufferを宣言
    CVPixelBufferRef buffer = NULL;
    
    // 現在のフレームカウント
    int frameCount = 0;
    // 各画像の表示する時間
    int durationForEachImage = 2;
    int32_t fps = kVideoFPS;
    
    /*
    @autoreleasepool {
        if (adaptor.assetWriterInput.readyForMoreMediaData) {
            // 動画の時間を生成（その画像の表示する時間。開始時点からの相対時間）
            //CMTime frameTime = CMTimeMake((int64_t)fps * durationForEachImage, fps);
            CMTime frameTime = kCMTimeZero;// 0から表示~endSessionまで
            
            buffer = [self pixelBufferFromCGImage:image.CGImage];
            
            if (![adaptor appendPixelBuffer:buffer withPresentationTime:frameTime]) {
                NSLog(@"Failed to append buffer. [image : %@]", image);
            }
            
            if(buffer) {
                CVBufferRelease(buffer);
            }
        }
    }
     */
    
    // memo:1枚の画像の場合、なぜか時間が0になってしまう。裏技？として同じ画像を２回書き出す(2sx2=4s)
    // todo:int型なので、奇数秒数の場合、1+2=3sの用に２倍ではなく、バラバラにする方法を取る(関数化)
    for (int i = 0; i < 2; i++) {
        @autoreleasepool {
            if (adaptor.assetWriterInput.readyForMoreMediaData) {
                // 動画の時間を生成（その画像の表示する時間。開始時点からの相対時間） a:0 b:3
                CMTime frameTime = CMTimeMake((int64_t)frameCount * fps * durationForEachImage, fps);
                
                NSLog(@"orientation:%ld width:%f height:%f", (long)image.imageOrientation, image.size.width, image.size.height);
                //UIImage *oriImage = [self rotateImage:image];
                //buffer = [self pixelBufferFromCGImage:oriImage.CGImage withOrientation:oriImage.imageOrientation];
                buffer = [self pixelBufferFromCGImage:image.CGImage withOrientation:image.imageOrientation size:image.size];
                
                if (![adaptor appendPixelBuffer:buffer withPresentationTime:frameTime]) {
                    NSLog(@"Failed to append buffer. [image : %@]", image);
                }
                
                if(buffer) {
                    CVBufferRelease(buffer);
                }
                
                frameCount++;
            }
        }
    }
    
    // 動画生成終了
    [writerInput markAsFinished];
    //[self.videoWriter endSessionAtSourceTime:CMTimeMake((int64_t)fps * durationForEachImage, fps)];
    //[self.videoWriter endSessionAtSourceTime:CMTimeMake((int64_t)frameCount * fps * durationForEachImage, fps)];
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Finish writing!@%ld", (long)self.videoWriter.status);
        if (self.videoWriter.status == AVAssetWriterStatusCompleted) {
            [self writeMovieCompleted:path];// create next
        } else {
            // todo:失敗して、呼ばれない場合、メモリリーク?(videoWriterは解放されない?)
            self.videoWriter = nil;
        }
    }];
    
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
}

/*
 画像の配列から動画を生成する。
 @param images 画像の配列
 @param path 動画ファイルの出力先
 */
- (void)writeImagesAsMovie:(NSArray *)images
                    toPath:(NSString *)path
{
    NSParameterAssert(images);
    NSParameterAssert(path);
    NSAssert((images.count > 0), @"Set least one image.");
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 既にファイルがある場合は削除する
    if ([fileManager fileExistsAtPath:path]) {
        [fileManager removeItemAtPath:path error:nil];
    }
    
    // 最初の画像から動画のサイズ指定する
    UIImage *img = (UIImage*)[images objectAtIndex:0];
    CGSize size = img.size;
    
    NSError *error = nil;
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        return;
    }
    
    // todo:その他Keyについて調査(AVVideoSettings.h)
    NSDictionary *outputSettings =
    @{// it must contain AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey.
      AVVideoCodecKey  : AVVideoCodecH264,//On iOS, the only values currently supported for AVVideoCodecKey are AVVideoCodecH264 and AVVideoCodecJPEG.
      AVVideoWidthKey  : @(size.width),
      AVVideoHeightKey : @(size.height),
      };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput
                                       assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:outputSettings];// AVFileTypeQuickTimeMovieの場合、nilも可
    // 必要であれば、transform/metadataの設定
    
    if ([self.videoWriter canAddInput:writerInput]) {
        [self.videoWriter addInput:writerInput];
    }
    
#if false
    NSDictionary *sourcePixelBufferAttributes =
    @{
      (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32ARGB),
      (NSString *)kCVPixelBufferWidthKey           : @(size.width),
      (NSString *)kCVPixelBufferHeightKey          : @(size.height),
      };
#else
    NSDictionary *sourcePixelBufferAttributes =
    @{
      (NSString *)kCVPixelBufferCGImageCompatibilityKey : [NSNumber numberWithBool:YES],
      (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey : [NSNumber numberWithBool:YES],
      (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32ARGB]};
#endif
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput
                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributes];
    
    writerInput.expectsMediaDataInRealTime = YES;
    
    // 生成開始できるか確認
    if (![self.videoWriter startWriting]) {
        NSLog(@"Failed to start writing.");
        return;
    }
    
    // 動画生成開始
    [self.videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // pixel bufferを宣言
    CVPixelBufferRef buffer = NULL;
    
    // 現在のフレームカウント
    int frameCount = 0;
    // 各画像の表示する時間
    int durationForEachImage = 3;
    int32_t fps = kVideoFPS;
    
    for (int i = 0; i < [images count]; i++) {
        UIImage *image = (UIImage*)[images objectAtIndex:i];
        @autoreleasepool {
            if (adaptor.assetWriterInput.readyForMoreMediaData) {
                // 動画の時間を生成（その画像の表示する時間。開始時点からの相対時間） a:0 b:3 c:6
                CMTime frameTime = CMTimeMake((int64_t)frameCount * fps * durationForEachImage, fps);
                
                buffer = [self pixelBufferFromCGImage:image.CGImage withOrientation:image.imageOrientation size:image.size];
                
                if (![adaptor appendPixelBuffer:buffer withPresentationTime:frameTime]) {
                    NSLog(@"Failed to append buffer. [image : %@]", image);
                }
                
                if(buffer) {
                    CVBufferRelease(buffer);
                }
                
                frameCount++;
            }
        }
    }
    
    // 動画生成終了
    [writerInput markAsFinished];
    // memo:あってもなくてもOK(ない場合、最後の一枚も3秒表示される。どうやって判断?)
    //[self.videoWriter endSessionAtSourceTime:CMTimeMake((int64_t)frameCount * fps * durationForEachImage, fps)];
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Finish writing!");
        // todo:失敗して、呼ばれない場合、メモリリーク?(videoWriterは解放されない?)
        self.videoWriter = nil;
    }];
    
    CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
}

- (NSArray*)imagesForAnimation:(UIImage*)orgImage
{
    NSMutableArray *images = [[NSMutableArray alloc] init];
    
    return images;
}

- (UIImageOrientation)airImageOrientation:/*(AirImageOrientation)*/(int)airOri
{
    UIImageOrientation orientation = UIImageOrientationRight;// portrait/up
    
    return orientation;
}

// とりあえず縦方向表示時の回転度数
- (CGFloat)imageRotationAngle:(UIImageOrientation)orientation
{
    CGFloat degree = 0;
    
    switch (orientation) {
        case UIImageOrientationUp:// デバイス:landscape/ホームボタン:right
            degree = 90;
            break;
        case UIImageOrientationDown:// landscape/left
            degree = -90;
            break;
        case UIImageOrientationRight:// portrait/up
            degree = 180;
            break;
        case UIImageOrientationLeft:// portrait/down
            degree = 0;
            break;
        default:
            degree = 0;
            break;
    }
    
    return degree * M_PI / 180.0;
}

- (UIImage*)rotateImage:(UIImage*)img
{
    CGImageRef      imgRef = [img CGImage];
    CGContextRef    context;
    CGFloat         width = img.size.width;
    CGFloat         height = img.size.height;
    UIImageOrientation orientation = img.imageOrientation;
    
    NSLog(@"orientation:%ld width:%f height:%f", (long)orientation, width, height);
    
    /*
    // todo:orientationごとに回転angleを変更するのはNG?表示方向がバラバラでも回転基準は同じらしい?(landscape/right?left?)
    // とりあえず、270(-90)に回転したら、全て上向きになっている。やっぱり基準はlandscape/left?
    // memo:サンプルの矢印はDevice向きに合わせているので、回転度数は同じ!矢印を上の状態(実際表示しない方向)で、Deviceの向きを変更した写真で確認する必要がある。やっぱり下記のswitch文が正しい
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, width), YES, img.scale);
    context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1, -1);
    CGContextRotateCTM(context, -M_PI_2);
     */
    
#if true
    switch (orientation) {
        case UIImageOrientationRight:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, width), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, height, width);
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, M_PI_2);
            break;
        case UIImageOrientationDown:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, width, 0);
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, -M_PI);
            break;
        case UIImageOrientationLeft:
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(height, width), YES, img.scale);
            context = UIGraphicsGetCurrentContext();
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, -M_PI_2);
            break;
        case UIImageOrientationUp:
        default:
            return img;
            break;
    }
    
#else
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, img.scale);
    context = UIGraphicsGetCurrentContext();
#endif
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    // imageOrientation:0になっているので、情報が失っている?
    UIImage*    oriImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSLog(@"oriImage orientation:%ld width:%f height:%f", (long)oriImage.imageOrientation, oriImage.size.width, oriImage.size.height);
    
    return oriImage;
}

//画像をピクセルバッファに変換する
// todo:orientationを関数化(横/縦情報を返す)。iPhone以外の場合、向き情報が異なる(ない)可能性があるので(ない場合width,heightで判断。iPhoneはdefaultで横向きサイズwidth>heightになっている)。
// todo:真っ黒になる！原点を中心に回転するので、angleだけ設定してはだめ！原点移動も含めて対応する必要がある。とりあえず、元画像を回転してから変換（この方法を参照）。
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image withOrientation:(UIImageOrientation)orientation size:(CGSize)size
{
    // ピクセルバッファを作成するためのオプションを設定
    NSDictionary *options = @{
                              (NSString *)kCVPixelBufferCGImageCompatibilityKey : @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
                              };
    
    CVPixelBufferRef pxbuffer = NULL;
    // memo:orientationによって、image.size.widthと異なる(orientation:0のサイズを取っている?)
    CGFloat width = CGImageGetWidth(image);
    CGFloat height = CGImageGetHeight(image);
    //CGFloat width = size.width;
    //CGFloat height = size.height;
    
    NSLog(@"orientation:%ld width:%f height:%f", (long)orientation, width, height);
    
    // ピクセルバッファを作成
    CVPixelBufferCreate(kCFAllocatorDefault,
                        width,
                        height,
                        kCVPixelFormatType_32ARGB,
                        (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    
    // ピクセルバッファをロック(readonly:1?)
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    
    // ピクセルバッファのベースアドレスのポインタを返す(描画用)
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    // カラースペースとコンテキストの作成
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 width,
                                                 height,
                                                 8, // RGBのbit数
                                                 4 * width, // size per line (bytes)
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
#if true
    // todo:orientationの情報がなくなる？ので、座標変換が必要？
    switch (orientation) {
        // todo:orientation情報がある場合、上向きに表示されるはず(システムが左?/右?に回転して表示？)
        // 情報がなくなるので、基準方向(landscape/right)になるので、上向きに手動で90度回転(右?/左?)が必要
        // 座標系、デバイスの向き、画像向きなどの変換について調査!!!
        case UIImageOrientationRight:
            CGContextTranslateCTM(context, width, height);
            CGContextScaleCTM(context, 1, -1);
            CGContextRotateCTM(context, M_PI_2);
            //CGContextTranslateCTM(context, -height, -width);// OK 変換順番要注意
            CGContextDrawImage(context, CGRectMake(0, 0, height, width), image);
            break;
        case UIImageOrientationUp:
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        default:
            break;
    }
    
#endif
    
#if false // todo:不要？逆転になる？横方向の画像はOK。縦方向の写真は90度回転になるので、対応が必要
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    // CG座標原点:左下
    // a=cos b=-sin
    // c=sin d=cos
    
    // a=1 b=0  tx=0
    // c=0 d=-1 ty=height
    // ->x'=ax+by=x
    //   y'=cx+dy=-y
    // ->x軸に上下裏返し反転->上にheight移動->上下反転
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, width);
    
    CGContextConcatCTM(context, flipVertical);
    
    // a=-1 b=0  tx=width
    // c=0  d=1  ty=0
    // ->x'=-x
    //   y'=y
    // ->y軸に左右裏返し(元に戻る)反転->右にwith移動
    // ->最終的に左下座標系が左上座標系になる
    CGAffineTransform flipHorizontal = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, width, 0.0);
    
    CGContextConcatCTM(context, flipHorizontal);
    
//#else
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    /*
    // a=cos b=-sin
    // c=sin d=cos
    // degree:90 -> 0, -1, 1, 0
    CGAffineTransform rotation = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
    CGContextConcatCTM(context, rotation);
    */
    
    CGFloat angle = [self imageRotationAngle:orientation];
    NSLog(@"orientation:%ld angle:%f width:%f height:%f", (long)orientation, angle, width, height);
    if (angle != 0 ) {
        // memo:Rotationすると正常に動画が作成されない？真っ暗になる
        //CGContextConcatCTM(context, CGAffineTransformMakeRotation(angle));
        //CGContextRotateCTM(context, angle);
    }
    /* // NG: width:3264.000000 height:2448.000000 .  width > height when portrait
    NSLog(@"width:%f height:%f", width, height);
    if (height > width) {
        
        CGFloat angle = -90 * M_PI / 180.0;
        CGContextConcatCTM(context, CGAffineTransformMakeRotation(angle));
    }*/
    
#endif
    
    // 画像をコンテキストに描画
    //CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    // カラースペースとコンテキストを解放
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    // ピクセルバッファのロックを解除
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

//
- (void)animateMovie:(NSString*)movPath frameCount:(int)count timeOfFrame:(float)time show:(NSString*)showPath
{
    //
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //AVMutableCompositionTrack *compositionSoundTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error;
    
    NSURL *inputURL = [NSURL fileURLWithPath:movPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    //
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    NSLog(@"asset track count:%lu", (unsigned long)[asset tracks].count);
    NSLog(@"asset track(video) count:%lu", (unsigned long)[asset tracksWithMediaType:AVMediaTypeVideo].count);
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count <= 0) {
        NSLog(@"no video track!");
        return;
    }
    
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    
    NSMutableArray *instructions = [NSMutableArray array];
    
    CGRect fromRect = CGRectMake(0, 0, videoTrack.naturalSize.width, videoTrack.naturalSize.height);
    CGRect toRect = CGRectMake(0, 0, videoTrack.naturalSize.width / 2, videoTrack.naturalSize.height / 2);
    
#if false
    CMTime movNextTime = kCMTimeZero;
    CMTime movDuration = CMTimeMake((int64_t)kVideoFPS * time, kVideoFPS);
    count = 1; // test
    for (int i = 0; i < count; i++) {
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        CMTimeRange frameTimeRange = CMTimeRangeMake(movNextTime, movDuration);
        instruction.timeRange = frameTimeRange;
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        [layerInstruction setOpacityRampFromStartOpacity:1.f
                                            toEndOpacity:0.f
                                               timeRange:frameTimeRange];
        [layerInstruction setCropRectangleRampFromStartCropRectangle:fromRect toEndCropRectangle:toRect timeRange:frameTimeRange];
        //[layerInstruction setTransform:transform atTime:kCMTimeZero];
        instruction.layerInstructions = @[layerInstruction];
        [instructions addObject:instruction];
        
        movNextTime = CMTimeAdd(movNextTime, movDuration);
    }
#else // ok
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = range;
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    [layerInstruction setOpacityRampFromStartOpacity:1.f
                                        toEndOpacity:0.f
                                           timeRange:range];
    [layerInstruction setCropRectangleRampFromStartCropRectangle:fromRect toEndCropRectangle:toRect timeRange:range];
    //[layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    [instructions addObject:instruction];
    
#endif
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoTrack.naturalSize;
    videoComposition.instructions = instructions;
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:showPath])
    {
        [fm removeItemAtPath:showPath error:&error];
    }
    
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
    for (NSString *preset in compatiblePresets) {
        NSLog(@"preset:%@", preset);
    }
    
    // memo:simのバグ.実機ではOK
    //AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetPassthrough];
    // memo:下記のpresetの場合、ダメな時がある。ただ、下記じゃないと、transformが効かない？！ todo:要調査!!
    //AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    // とりあえず
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480];
    session.outputURL = [NSURL fileURLWithPath:showPath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

- (void)addSoundToMovie:(NSString*)movPath sound:(NSString*)soundPath show:(NSString*)showPath
{
    //
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSError *error;
    
    NSURL *inputURL = [NSURL fileURLWithPath:movPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    //
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVAssetTrack *videoTrack = nil;
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks == nil || videoTracks.count <= 0) {
        NSLog(@"No video tracks");
        return;
    }
    videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    
    // 音楽の編集はしないので、とりあえず不要
    //AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];// 要る??
    //[compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = range;
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    //
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    AVURLAsset *soundAsset = [[AVURLAsset alloc] initWithURL:soundURL options:nil];
    AVAssetTrack *soundTrack = [soundAsset tracksWithMediaType:AVMediaTypeAudio][0];
    AVMutableCompositionTrack *compositionSoundTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionSoundTrack insertTimeRange:range ofTrack:soundTrack atTime:kCMTimeZero error:&error];
    
    CGSize videoSize = videoTrack.naturalSize;
    NSLog(@"videoSize(before):[%f, %f]", videoSize.width, videoSize.height);
    
    CGAffineTransform transform = videoTrack.preferredTransform;;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
        NSLog(@"videoSize(after):[%f, %f]", videoSize.width, videoSize.height);
    }
    
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:showPath])
    {
        [fm removeItemAtPath:showPath error:&error];
    }
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:showPath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"Complete export!%ld", (long)session.status);
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
            if (_observer != nil) {
                if ([_observer respondsToSelector:@selector(progress:inCreatingShow:)]) {
                    [_observer progress:100 inCreatingShow:showPath];
                }
            }
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

// 複数の動画(横モード)と音声を合成
- (void)addSoundToMovies:(NSArray*)movPathList sound:(NSString*)soundPath show:(NSString*)showPath
{
    NSError *error;
    
    //
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    CGSize movSize = CGSizeZero;
    CMTime movStartTime = kCMTimeZero;
    for (int i = 0; i < movPathList.count; i++) {
        NSString *movPath = [movPathList objectAtIndex:i];
        NSURL *inputURL = [NSURL fileURLWithPath:movPath];
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        CMTimeRange videoRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
        
        [compositionVideoTrack insertTimeRange:videoRange ofTrack:videoTrack atTime:movStartTime error:&error];
        
        // set max of size
        if (videoTrack.naturalSize.width > movSize.width) {
            movSize.width = videoTrack.naturalSize.width;
        }
        if (videoTrack.naturalSize.height > movSize.height) {
            movSize.height = videoTrack.naturalSize.height;
        }
        // next movie start time
        movStartTime = CMTimeAdd(movStartTime, videoTrack.timeRange.duration);
    }
    
    //
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    AVURLAsset *soundAsset = [[AVURLAsset alloc] initWithURL:soundURL options:nil];
    //CMTimeRange soundRange = CMTimeRangeMake(kCMTimeZero, soundAsset.duration);
    CMTimeRange soundRange = CMTimeRangeMake(kCMTimeZero, movStartTime);// all movie duration
    AVAssetTrack *soundTrack = [soundAsset tracksWithMediaType:AVMediaTypeAudio][0];
    AVMutableCompositionTrack *compositionSoundTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionSoundTrack insertTimeRange:soundRange ofTrack:soundTrack atTime:kCMTimeZero error:&error];
    
    /*
    CGSize videoSize = videoTrack.naturalSize;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
     */
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, movStartTime);
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    [layerInstruction setOpacityRampFromStartOpacity:1.f
                                        toEndOpacity:0.f
                                           timeRange:CMTimeRangeMake(kCMTimeZero, movStartTime)];
    //[layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = movSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:showPath])
    {
        [fm removeItemAtPath:showPath error:&error];
    }
    
    // memo:simのバグ.実機ではOK
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                     presetName:AVAssetExportPresetHighestQuality];
    
#if false
    // Set the desired output URL for the file created by the export process.
    // Create a static date formatter so we only have to initialize it once.
    static NSDateFormatter *kDateFormatter;
    if (!kDateFormatter) {
        kDateFormatter = [[NSDateFormatter alloc] init];
        kDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        kDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    session.outputURL = [[[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                 inDomain:NSUserDomainMask
                                                        appropriateForURL:nil
                                                                   create:@YES
                                                                    error:nil]
                          URLByAppendingPathComponent:[kDateFormatter stringFromDate:[NSDate date]]]
                         URLByAppendingPathExtension:CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
#endif
    
    session.outputURL = [NSURL fileURLWithPath:showPath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.shouldOptimizeForNetworkUse = YES;
    session.videoComposition = videoComposition;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
#if true
        if (session.status == AVAssetExportSessionStatusCompleted){
             NSLog(@"output complete!");
        } else {
            NSLog(@"output error! : %@", session.error);
        }
        
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            if (session.status == AVAssetExportSessionStatusCompleted){
                NSLog(@"output complete!");
                ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
                if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
                    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:NULL];
                }
            }
        });
#endif
    }];
}

// 複数の動画を合成
// memo:
// 複数のvideo(AVAssetTrack)を一つのAVMutableCompositionTrackに繋げる(timeRange:各video atTime:xxxComxxxTrackで当該track開始時間)
// videoごとにAVMutableVideoCompositionInstructionを作成。timeRangeはxxxComxxxTrackでの当該track開始時間~videoのduration。必要なら複数のAVMutableVideoCompositionLayerInstructionを追加(range:はinstructionのstartTimeから)
// todo:AVMutableCompositionTrack,AVMutableVideoCompositionInstruction,AVMutableVideoCompositionLayerInstructionの関係、timeRangeについて調査(複数の場合)
/*
 *
 * ------------------------------------
 * AVAssetTrack1(5s)                  |    empty       AVMutableCompositionTrack1(insert:0-5s at:0s)
 * ------------------------------------
 *                       ----------------------------------
 *   empty               |AVAssetTrack2(5s)            AVMutableCompositionTrack2(insert:0-5s at:3s)
 *                       ----------------------------------
 * 0s                    3s           5s
 *
 * --------------------------------------------------------
 *                AVMutableComposition
 * --------------------------------------------------------
 *
 * ----------------------
 * CompositionInstruction(for CompositionTrack1 in range[0->3])
 * ----------------------
 *                       --------------
 * CompositionInstruction(for CompositionTrack1/2 with CompositionLayerInstruction in range[3->2])
 *                       --------------
 *                                     --------------------
 *                                     CompositionInstruction(for CompositionTrack2 in range[5->3])
 *                                     --------------------
 *
 * CompositionInstructionはCompositionLayerInstructionを管理(設定順によってlayer順が決まる)するが、CompositionTrackを意識しない。CompositionLayerInstructionでCompositionTrack(一部/全部)どう操作するか設定する。
 * CompositionInstructionで管理するLayerは異なるCompositionTrackで生成されることがある(重なるCompositionTrackの場合とか)。
 * 複数のCompositionInstructionを生成するのは可能だが(境界線での動作がスムーズではない？)、複数のLayerで管理した方が良い。
 */
- (void)connectMovies:(NSArray*)movPathList movie:(NSString*)moviePath
{
    NSError *error;
    
    //
    AVMutableComposition *composition = [AVMutableComposition composition];
    // todo:最大15個?。特別な処理がなければ、基本１個の方が良い?音声でBGMなどを入れる場合、複数で良いかも
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    NSMutableArray *instructions = [NSMutableArray array];
    //NSMutableArray *layerInstructions = [NSMutableArray array];
    CGSize movSize = CGSizeZero;
    CMTime movStartTime = kCMTimeZero;
    // todo:AVMutableCompositionTrackは何個まで？15?
    for (int i = 0; i < movPathList.count; i++) {
        NSString *movPath = [movPathList objectAtIndex:i];
        NSURL *inputURL = [NSURL fileURLWithPath:movPath];
        AVURLAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
        AVAssetTrack *videoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        //CMTimeRange videoRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
        CMTimeRange videoRange = videoTrack.timeRange;
        
        // memo:videoTrackのvideoRangeの部分をcompositionVideoTranckのmovStartTimeに挿入
        [compositionVideoTrack insertTimeRange:videoRange ofTrack:videoTrack atTime:movStartTime error:&error];
        //[compositionVideoTrack setPreferredTransform:videoTrack.preferredTransform];
        
        /*
         CGSize videoSize = videoTrack.naturalSize;
         CGAffineTransform transform = videoTrack.preferredTransform;
         if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
         {
         videoSize = CGSizeMake(videoSize.height, videoSize.width);
         }
         */
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [self movieEffectLayerInstruction:AirMovieEffectTypeScaleDown OfTrack:videoTrack startTime:movStartTime forCompositionTrack:compositionVideoTrack];
        
        //[layerInstructions addObject:layerInstruction];
        
        // todo:movieごとに作成した方がやりやすい?(layerの時間0-durationまで調整しやすい)
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        //instruction.timeRange = videoRange;// NG
        instruction.timeRange = CMTimeRangeMake(movStartTime, videoTrack.timeRange.duration);
        instruction.layerInstructions = @[layerInstruction];
        [instructions addObject:instruction];
        
        // set min of size
        if (videoTrack.naturalSize.width > movSize.width) {
            movSize.width = videoTrack.naturalSize.width;
        }
        if (videoTrack.naturalSize.height > movSize.height) {
            movSize.height = videoTrack.naturalSize.height;
        }
        // next movie start time
        movStartTime = CMTimeAdd(movStartTime, videoTrack.timeRange.duration);
    }
    
    // todo:movieごとに作成した方がやりやすい?(layerの時間0-durationまで調整しやすい)
    //AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //instruction.timeRange = videoRange;
    //instruction.timeRange = CMTimeRangeMake(kCMTimeZero, movStartTime);
    //instruction.layerInstructions = layerInstructions;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = movSize;
    //videoComposition.instructions = @[instruction];
    videoComposition.instructions = instructions;
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:moviePath])
    {
        [fm removeItemAtPath:moviePath error:&error];
    }
    
    // memo:simのバグ.実機ではOK
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition
                                                                    //presetName:AVAssetExportPresetPassthrough];
                                                                     presetName:AVAssetExportPresetHighestQuality];
    
#if false
    // Set the desired output URL for the file created by the export process.
    // Create a static date formatter so we only have to initialize it once.
    static NSDateFormatter *kDateFormatter;
    if (!kDateFormatter) {
        kDateFormatter = [[NSDateFormatter alloc] init];
        kDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        kDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    session.outputURL = [[[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                 inDomain:NSUserDomainMask
                                                        appropriateForURL:nil
                                                                   create:@YES
                                                                    error:nil]
                          URLByAppendingPathComponent:[kDateFormatter stringFromDate:[NSDate date]]]
                         URLByAppendingPathExtension:CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
#endif
    
    session.outputURL = [NSURL fileURLWithPath:moviePath];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.shouldOptimizeForNetworkUse = YES;
    session.videoComposition = videoComposition;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
#if true
        NSLog(@"Complete export!%ld", (long)session.status);
        if (session.status == AVAssetExportSessionStatusCompleted){
            NSLog(@"output complete!");
            if (_observer != nil) {
                if ([_observer respondsToSelector:@selector(progress:inConnectingMovies:)]) {
                    [_observer progress:100 inConnectingMovies:moviePath];
                }
            }
        } else {
            NSLog(@"output error! : %@", session.error);
        }
        
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            if (session.status == AVAssetExportSessionStatusCompleted){
                NSLog(@"output complete!");
                ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
                if ([assetsLibrary videoAtPathIsCompatibleWithSavedPhotosAlbum:exporter.outputURL]) {
                    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:exporter.outputURL completionBlock:NULL];
                }
            }
        });
#endif
    }];
}

- (AVMutableVideoCompositionLayerInstruction*)movieEffectLayerInstruction:(AirMovieEffectType)type OfTrack:(AVAssetTrack*)videoTrack startTime:(CMTime)startTime forCompositionTrack:(AVAssetTrack*)compositionVideoTrack
{
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    CGAffineTransform transform = videoTrack.preferredTransform;
    CGAffineTransform startTransform = transform;
    CGAffineTransform endTransform = transform;
    CMTimeRange videoRange = CMTimeRangeMake(startTime, videoTrack.timeRange.duration);
    CGFloat zoomScale = 1.2;
    
    switch (type) {
        case AirMovieEffectTypeScaleUp:
            //startTransform = CGAffineTransformMakeScale(1.0 / zoomScale, 1.0 / zoomScale);
            startTransform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1.0 / zoomScale, 1.0 / zoomScale));
            endTransform = transform;
            break;
        case AirMovieEffectTypeScaleDown:
            startTransform = CGAffineTransformMakeScale(zoomScale, zoomScale);
            //startTransform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(zoomScale, zoomScale));
            endTransform = transform;
            break;
        case AirMovieEffectTypeNone:
        default:
            break;
    }
    
    [layerInstruction setTransformRampFromStartTransform:startTransform toEndTransform:endTransform timeRange:videoRange];
    
    return layerInstruction;
}

// fromからduration分をカット
- (void)cutMovie:(NSString*)movPath savePath:(NSString*)savePath from:(float)startTime duration:(float)duration
{
    // 1
    NSString *inputPath = movPath;
    NSString *outputPaht = savePath;
    
    // 2
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    
    // 3
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    // 4
    if (startTime >= CMTimeGetSeconds(asset.duration) || startTime < 0 || duration <= 0)
        return;
    
    CMTime rangeStart = CMTimeMakeWithSeconds(startTime, kVideoFPS);
    CMTime rangeDuration = CMTimeMakeWithSeconds(duration, kVideoFPS);
    CMTimeRange inputRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    CMTimeRange outputRange = CMTimeRangeMake(rangeStart, rangeDuration);
    
    // 5
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // 6 outputRange(videoTrackのoutputRange部分をcompositionViewTrackの開始位置kCMTimeZeroに持ってくる)
    [compositionVideoTrack insertTimeRange:outputRange ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:outputRange ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    // 7 inputRange
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = inputRange;
    
    // 8
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    // 9
    // 実際に保存された動画は「横向きの動画を回転して縦向きにみせる動画」として保存されている
    CGSize videoSize = videoTrack.naturalSize;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    // 10
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    // 11
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    // 12
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPaht])
    {
        [fm removeItemAtPath:outputPaht error:&error];
    }
    
    // 13
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:outputPaht];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    //session.timeRange = outputRange;// todo:これだけでもtrimming可能かも(videoCompositionあっても良い？)。未確認
    
    // 14
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

// 切り出す
- (void)clipMovie:(NSString*)movPath savePath:(NSString*)savePath clipSize:(CGSize)clipSize
{
    // 1
    NSString *inputPath = movPath;
    NSString *outputPaht = savePath;
    
    // 2
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    
    // 3
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    // 4
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    // 5
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // 6 outputRange(videoTrackのoutputRange部分をcompositionViewTrackの開始位置kCMTimeZeroに持ってくる)
    [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    // 7 inputRange
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = range;
    
    // 8
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    // 9
    // 実際に保存された動画は「横向きの動画を回転して縦向きにみせる動画」として保存されている
    CGSize videoSize = videoTrack.naturalSize;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    // 10
    // 切り出すサイズ
    videoSize = clipSize;
    // 切り出す位置(元画像の原点位置を変更)
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(-100, -600));
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    // 11
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    // 12
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPaht])
    {
        [fm removeItemAtPath:outputPaht error:&error];
    }
    
    // 13
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:outputPaht];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    //session.timeRange = outputRange;// todo:これだけでもtrimming可能かも(videoCompositionあっても良い？)。未確認
    
    // 14
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

// 拡大、縮小
- (void)zoomMovie:(NSString*)movPath savePath:(NSString*)savePath zoomScale:(float)zoomScale
{
    // 1
    NSString *inputPath = movPath;
    NSString *outputPaht = savePath;
    
    // 2
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    
    // 3
    NSURL *inputURL = [NSURL fileURLWithPath:inputPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    // 4
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    // 5
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
    
    // 6 outputRange(videoTrackのoutputRange部分をcompositionViewTrackの開始位置kCMTimeZeroに持ってくる)
    [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
    // 7 inputRange
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = range;
    
    // 8
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    // 9
    // 実際に保存された動画は「横向きの動画を回転して縦向きにみせる動画」として保存されている
    CGSize videoSize = videoTrack.naturalSize;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    // 10
    // 必要であれば、videoSizeも合わせて変更する(表示はどうなる？？)
    //videoSize = CGSizeMake(videoSize.width * zoomScale, videoSize.height * zoomScale);
    transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(zoomScale, zoomScale));
    [layerInstruction setTransform:transform atTime:kCMTimeZero];
    instruction.layerInstructions = @[layerInstruction];
    
    // 11
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.instructions = @[instruction];
    videoComposition.frameDuration = CMTimeMake(1, kVideoFPS);
    
    // 12
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPaht])
    {
        [fm removeItemAtPath:outputPaht error:&error];
    }
    
    // 13
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    session.outputURL = [NSURL fileURLWithPath:outputPaht];
    session.outputFileType = AVFileTypeQuickTimeMovie;
    session.videoComposition = videoComposition;
    //session.timeRange = outputRange;// todo:これだけでもtrimming可能かも(videoCompositionあっても良い？)。未確認
    
    // 14
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted)
        {
            NSLog(@"output complete!");
        }
        else
        {
            NSLog(@"output error! : %@", session.error);
        }
    }];
}

@end
