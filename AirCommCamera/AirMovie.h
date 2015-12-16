//
//  AirMovie.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "AirFile.h"

typedef enum : int64_t {
    AirMovieEffectTypeNone        = 0,
    AirMovieEffectTypeScaleUp     = 1 << 0,
    AirMovieEffectTypeScaleDown   = 1 << 1,
    AirMovieEffectTypeRotation    = 1 << 2,
    AirMovieEffectTypeTranslation = 1 << 3,
    AirMovieEffectTypeCustom      = 1 << 63,//0xf??
} AirMovieEffectType;

typedef enum : int64_t {
    AirMovieTransitionTypeNone        = 0,
    AirMovieTransitionTypeFade        = 1 << 0,// in -> out
    AirMovieTransitionTypeRotation    = 1 << 1,// scaleUp -> scaleDown
    AirMovieTransitionTypeTranslation = 1 << 2,//
    AirMovieTransitionTypeOverlap     = 1 << 3,// rotation+scaleDown+translation(for end)
    AirMovieTransitionTypeCustom      = 1 << 63,//0xf??
} AirMovieTransitionType;

typedef enum : int64_t {
    AirMovieTransformTypeNone                       = 0,
    AirMovieTransformTypeFadeIn                     = 1 << 0,// in -> out
    AirMovieTransformTypeFadeOut                    = 1 << 1,
    AirMovieTransformTypeScaleUp                    = 1 << 2,
    AirMovieTransformTypeScaleDown                  = 1 << 3,
    AirMovieTransformTypeRotationRight              = 1 << 4,//
    AirMovieTransformTypeRotationLeft               = 1 << 5,//
    AirMovieTransformTypeTranslationHorizontal      = 1 << 6,// right->left
    AirMovieTransformTypeTranslationVertical        = 1 << 7,// down->up
    AirMovieTransformTypeFlipHorizontal             = 1 << 8,// down->up
    AirMovieTransformTypeFlipVertical               = 1 << 9,// right->left
    AirMovieTransformTypeOverlap                    = 1 << 31,// custom:rotation+scaleDown+translation(for end)
    AirMovieTransformTypeCustom                     = 1 << 63,//0xf??
} AirMovieTransformType;

// 1.33:1 / 4:3 / SDTV、1.375:1 / フィルム、 1.77 / 16.9 / HDTV、1.85:1 / フィルム、2:39:1または2:40:1 / ワイドスクリーン
typedef enum {
    AirMovieAspectRatioSDTV,
    AirMovieAspectRatioHDTV,
} AirMovieAspectRatio;

typedef enum {
    AirMovieSizeHD,
    AirMovieSizeFHD,
    AirMovieSize4K,
    AirMovieSize8K,
} AirMovieSize;

@interface AirMovieTransformInfo : NSObject

@property (nonatomic) CMTime effectTime;
@property (nonatomic) CMTime transitionInTime;
@property (nonatomic) CMTime transitionOutTime;
@property (nonatomic) AirMovieTransformType effectType;
@property (nonatomic) AirMovieTransformType transitionTypeIn;
@property (nonatomic) AirMovieTransformType transitionTypeOut;
@property (nonatomic) CGAffineTransform currentTransform;
@property (nonatomic) float currentOpcity;
@property (nonatomic) CGFloat zoomScale;

@end

@interface AirMovie : AirFile

//@property (nonatomic, copy) NSString *moviePath;
@property (nonatomic) UIImage *thumbnailImage;
@property (nonatomic) AirMovieTransformInfo *transformInfo;

@end
