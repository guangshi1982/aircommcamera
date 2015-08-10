//
//  AirImageManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/08.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import "AirImageManager.h"

@implementation DetectInfo


@end

@interface AirImageManager()

@property (nonatomic) CIDetector *detector;

@end

@implementation AirImageManager

+(AirImageManager*)getInstance
{
    static AirImageManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AirImageManager new];
    });
    
    return sharedInstance;
}

-(id)init
{
    if (self = [super init]) {
        NSDictionary *options = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh
                                                            forKey:CIDetectorAccuracy];
        _detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                       context:nil
                                       options:options];
    }
    
    return self;
}

-(NSArray*)detectFace:(UIImage*)image
{
    NSMutableArray *faces = [[NSMutableArray alloc] init];
    // 顔検出
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:image.CGImage];
    NSDictionary *imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:CIDetectorImageOrientation];
    NSArray *array = [_detector featuresInImage:ciImage options:imageOptions];
    
    // CoreImageは、左下の座標が (0,0) となるので、UIKitと同じ座標系に変換
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    
    // 検出されたデータを取得
    for (CIFaceFeature *faceFeature in array)
    {
        DetectInfo *info = [[DetectInfo alloc] init];
        Face face;
        
        // 座標変換
        CGRect faceRect = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        face.bounds = faceRect;
        
        if (faceFeature.hasLeftEyePosition) {
            CGPoint leftEyePos = CGPointApplyAffineTransform(faceFeature.leftEyePosition, transform);
            face.leftEyePosition = leftEyePos;
            face.leftEyeClosed = faceFeature.leftEyeClosed;
        }
        
        if (faceFeature.hasRightEyePosition) {
            CGPoint rightEyePos = CGPointApplyAffineTransform(faceFeature.rightEyePosition, transform);
            face.rightEyePosition = rightEyePos;
            face.rightEyeClosed = faceFeature.rightEyeClosed;
        }
        
        if (faceFeature.hasMouthPosition) {
            CGPoint mouthEyePos = CGPointApplyAffineTransform(faceFeature.mouthPosition, transform);
            face.mouthPosition = mouthEyePos;
        }
        
        if (faceFeature.hasFaceAngle) {
            face.faceAngle = faceFeature.faceAngle;
        }
        
        if (faceFeature.hasTrackingID) {
            face.trackingID = faceFeature.trackingID;
        }
        
        if (faceFeature.hasTrackingFrameCount) {
            face.trackingFrameCount = faceFeature.trackingFrameCount;
        }
        
        face.hasSmile = faceFeature.hasSmile;
        
        info.face = face;
        [faces addObject:info];
    }
    
    return faces;
}

@end
