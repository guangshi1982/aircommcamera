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

typedef enum : int64_t {
    AirImageEffectTypeNone,
    AirImageEffectTypeCustom,
} AirImageEffectType;

@interface AirImage : AirFile

// from super class
//@property (nonatomic, copy) NSString *imagePath;
//@property (nonatomic, copy) NSString *imageName;
//@property (nonatomic, copy) NSString *imageNameExt;
@property (nonatomic) UIImage *image;
@property (nonatomic) AirImageEffectType effectType;

- (id)initWithItem:(FAItem *)item;
- (id)initWithImage:(UIImage*)image;

@end
