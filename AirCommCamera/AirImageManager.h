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
    BOOL hasMouth;
    BOOL hasLeftEye;
    BOOL hasRightEye;
    
    BOOL leftEyeClosed;
    BOOL rightEyeClosed;
    
} Face;

@interface DetectInfo : NSObject

@property (nonatomic) Face face;

@end

// 画像処理
@interface AirImageManager : NSObject

+(AirImageManager*)getInstance;
-(NSArray*)detectFace:(UIImage*)image inBounds:(CGRect)bounds;
-(NSArray*)imageFilterCategories;
-(NSArray*)imageFilterNamesInCategory:(NSString*)category;
-(NSArray*)imageFilterNamesInCategories:(NSArray*)categories;
-(UIImage*)imageFilteredWithName:(NSString*)name image:(UIImage*)image;
-(NSArray*)imagesFilteredWithNames:(NSArray*)names image:(UIImage*)image;
-(UIImage*)resizeImageToFill:(UIImage*)orgImage bounds:(CGRect)bounds;

@end
