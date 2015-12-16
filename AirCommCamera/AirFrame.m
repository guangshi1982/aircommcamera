//
//  AirFrame.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/27.
//  Copyright © 2015年 Threees. All rights reserved.
//

#import "AirFrame.h"
#import "AirImageManager.h"

@interface AirFrame()

@end

@implementation AirFrame

- (id)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer transform:(CGAffineTransform)transform
{
    if (self = [super init]) {
        _pixelBuffer = pixelBuffer;
        _transform = transform;
    }
    
    return self;
}

- (id)initWithImage:(UIImage*)image transform:(CGAffineTransform)transform
{
    if (self = [super init]) {
        AirImageManager *airImageMan = [AirImageManager getInstance];
        _pixelBuffer = [airImageMan pixelBufferFromImage:image];
        _transform = transform;
    }

    return self;
}

@end
