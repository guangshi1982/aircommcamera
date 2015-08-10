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

@interface AirShowManager()

@property (nonatomic, strong) AVAssetWriter *videoWriter;

//@property (nonatomic, copy) NSString *soundPath;
@property (nonatomic, copy) NSString *movPath;
//@property (nonatomic, copy) NSString *showPath;

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
        _movPath = [FileManager getPathWithFileName:@"tmp.mov" fromFolder:@"/airmovie"];
    }
    
    return self;
}

/*
- (void)setSoundPath:(NSString*)soundPath showPath:(NSString*)showPath
{
    _soundPath = soundPath;
    _showPath = showPath;
    _movPath = [FileManager getPathWithFileName:@"tmp.mov" fromFolder:@"/airmovie"];
}
 */
 

- (UIImage*)thumbnailOfVideo:(NSString*)videoPath
{
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
    
    return thumnail;
}

- (void)createSlideShowWithImages:(NSArray *)images sound:(NSString*)soundPath show:(NSString*)showPath
{
    if (images != nil && soundPath != nil && showPath != nil) {
#if false
        // todo:シリアルキューで順番に複数動画を作成(非同期で作成するので、キューを使わないと、一部正常に生成されない。。。)
        NSMutableArray *moviePathList = [[NSMutableArray alloc] init];
        for (int i = 0; i < images.count; i++) {
            NSString *moviePath = [FileManager getPathWithFileName:[NSString stringWithFormat:@"tmp%d.mov", i] fromFolder:@"/airmovie"];
            [self writeImageToMovie:images[i] toPath:moviePath];
            [moviePathList addObject:moviePath];
        }
#endif
        
#if false // create show from animation(created with images) and sound
        // animation layer seems to be ok. need base video for adding the layer??
        CALayer *layer = [self animationLayerWithImages:images];
        [self createSlideShowWithAnimationLayer:layer sound:soundPath show:showPath];
#endif
        
#if true // create show from images and sound
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
    
    // 各画像の表示する時間
    int durationForEachImage = 3;
    int32_t fps = kVideoFPS;
    
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
    
    // 動画生成終了
    [writerInput markAsFinished];
    [self.videoWriter endSessionAtSourceTime:CMTimeMake((int64_t)fps * durationForEachImage, fps)];
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"Finish writing!");
        // todo:失敗して、呼ばれない場合、メモリリーク?(videoWriterは解放されない?)
        self.videoWriter = nil;
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
                
                buffer = [self pixelBufferFromCGImage:image.CGImage];
                
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

//画像をピクセルバッファに変換する
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image
{
    // ピクセルバッファを作成するためのオプションを設定
    NSDictionary *options = @{
                              (NSString *)kCVPixelBufferCGImageCompatibilityKey : @(YES),
                              (NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
                              };
    
    CVPixelBufferRef pxbuffer = NULL;
    
    // ピクセルバッファを作成
    CVPixelBufferCreate(kCFAllocatorDefault,
                        CGImageGetWidth(image),
                        CGImageGetHeight(image),
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
                                                 CGImageGetWidth(image),
                                                 CGImageGetHeight(image),
                                                 8, // RGBのbit数
                                                 4 * CGImageGetWidth(image), // size per line (bytes)
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, CGImageGetHeight(image));
    
    CGContextConcatCTM(context, flipVertical);
    
    CGAffineTransform flipHorizontal = CGAffineTransformMake(-1.0, 0.0, 0.0, 1.0, CGImageGetWidth(image), 0.0);
    
    CGContextConcatCTM(context, flipHorizontal);
    
    // 画像をコンテキストに描画
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
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
    AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    
    NSURL *inputURL = [NSURL fileURLWithPath:movPath];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    //
    CMTimeRange range = CMTimeRangeMake(kCMTimeZero, asset.duration);
    
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];// 要る??
    
    [compositionVideoTrack insertTimeRange:range ofTrack:videoTrack atTime:kCMTimeZero error:&error];
    [compositionAudioTrack insertTimeRange:range ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    
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
    CGAffineTransform transform = videoTrack.preferredTransform;;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0))
    {
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
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
