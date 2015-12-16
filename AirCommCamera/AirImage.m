//
//  AirImage.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/13.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirImage.h"
#import "AirFileManager.h"


@implementation AirImageExif


@end

@implementation AirImage

- (id)initWithItem:(FAItem *)item
{
    if (self = [super initWithItem:item]) {
        NSData *data = [[AirFileManager getInstance] getFileData:self.filePath];
        //_image = [UIImage imageNamed:self.filePath];
        if (data) {
            _image = [UIImage imageWithData:data];
        } else {
            // todo: dummy data
        }
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

- (id)initWithData:(NSData*)data
{
    if (self = [super init]) {
        _image = [UIImage imageWithData:data];
    }
    
    return self;
}

@end
