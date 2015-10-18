//
//  AirMovie.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AirFile.h"

typedef enum : int64_t {
    AirMovieEffectTypeNone        = 0x0000000000000000,
    AirMovieEffectTypeTranslation = 0x0000000000000001,
    AirMovieEffectTypeScaleUp     = 0x0000000000000002,
    AirMovieEffectTypeScaleDown   = 0x0000000000000004,
    AirMovieEffectTypeRotation    = 0x0000000000000008,
    AirMovieEffectTypeCustom      = 0x4000000000000000,//0xf??
} AirMovieEffectType;

typedef enum : int64_t {
    AirMovieTransitionTypeNone        = 0x0000000000000000,
    AirMovieTransitionTypeFadeIn      = 0x0000000000000001,
    AirMovieTransitionTypeFadeOut     = 0x0000000000000002,
    AirMovieTransitionTypeCustom      = 0x4000000000000000,//0xf??
} AirMovieTransitionType;

@interface AirMovie : AirFile

//@property (nonatomic, copy) NSString *moviePath;
@property (nonatomic) UIImage *thumbnailImage;
@property (nonatomic) AirMovieEffectType effectType;
@property (nonatomic) AirMovieTransitionType transitionType;

@end
