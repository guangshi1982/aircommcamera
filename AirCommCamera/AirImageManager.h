//
//  AirImageManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/08.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef struct {
    CGRect bounds;
    CGPoint leftEyePosition;
    CGPoint rightEyePosition;
    CGPoint mouthPosition;
    
    int trackingID;
    int trackingFrameCount;
    
    float faceAngle;
    
    BOOL hasSmile;
    BOOL leftEyeClosed;
    BOOL rightEyeClosed;
    
} Face;

@interface DetectInfo : NSObject

@property (nonatomic) Face face;

@end

// 画像処理
@interface AirImageManager : NSObject

+(AirImageManager*)getInstance;
-(NSArray*)detectFace:(UIImage*)image;

@end
