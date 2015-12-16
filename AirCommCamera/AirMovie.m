//
//  AirMovie.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirMovie.h"

#define kVideoFPS   24

@implementation AirMovieTransformInfo

- (id)init
{
    if (self = [super init]) {
        _effectTime = CMTimeMake(2 * kVideoFPS, kVideoFPS);
        _transitionInTime = CMTimeMake(1 * kVideoFPS, kVideoFPS);
        _transitionOutTime = CMTimeMake(1 * kVideoFPS, kVideoFPS);
        _effectType = AirMovieTransformTypeScaleUp;
        _transitionTypeIn = AirMovieTransformTypeNone;
        _transitionTypeOut = AirMovieTransformTypeFadeOut;
        _currentTransform = CGAffineTransformIdentity;
        _currentOpcity = 1.0;
        _zoomScale = 1.2;
    }
    
    return self;
}

@end

@implementation AirMovie

- (id)initWithPath:(NSString*)path
{
    if (self = [super initWithPath:path]) {
        _transformInfo = [[AirMovieTransformInfo alloc] init];
    }
    
    return self;
}

@end
