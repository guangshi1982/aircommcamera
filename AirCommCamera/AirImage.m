//
//  AirImage.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirImage.h"


@implementation AirImageExif


@end

@implementation AirImage

- (id)initWithItem:(FAItem *)item
{
    if (self = [super initWithItem:item]) {
        _image = [UIImage imageNamed:self.filePath];
    }
    
    return self;
}

- (id)initWithPath:(NSString*)path
{
    if (self = [super initWithPath:path]) {
        _image = [UIImage imageNamed:path];
    }
    
    return self;
}

- (id)initWithImage:(UIImage*)image
{
    if (self = [super init]) {
        _image = image;
    }
    
    return self;
}

@end
