//
//  AirFrame.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/27.
//  Copyright © 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

@interface AirFrame : NSObject

// todo:copy?
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property (nonatomic) CGAffineTransform transform;

- (id)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer transform:(CGAffineTransform)transform;
- (id)initWithImage:(UIImage*)image transform:(CGAffineTransform)transform;

@end
