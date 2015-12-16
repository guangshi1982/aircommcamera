//
//  AirImage.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AirFile.h"
#import "AirSensorManager.h"

typedef enum : int64_t {
    AirImageEffectTypeNone,
    AirImageEffectTypeCustom,
} AirImageEffectType;

typedef enum {
    AirImageAspectRatio4x3,
    AirImageAspectRatio16x9,
} AirImageAspectRatio;

typedef enum {
    AirImageSize1280x720,
    AirImageSize1920x1080,
} AirImageSize;

@interface AirImageExif : NSObject

@property (nonatomic) AirSensorInfo *sensorInfo;

@end

@interface AirImage : AirFile

// from super class
//@property (nonatomic, copy) NSString *imagePath;
//@property (nonatomic, copy) NSString *imageName;
//@property (nonatomic, copy) NSString *imageNameExt;
@property (nonatomic) UIImage *image;
@property (nonatomic) AirImageEffectType effectType;
@property (nonatomic) AirImageExif *imageExif;

- (id)initWithItem:(FAItem *)item;
- (id)initWithImage:(UIImage*)image;
- (id)initWithData:(NSData*)data;

@end
