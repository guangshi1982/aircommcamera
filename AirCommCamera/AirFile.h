//
//  AirFile.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/15.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FAItem.h"

typedef enum {
    AirFileTypeFile = 0,
    AirFileTypeFolder,
} AirFileType;

typedef enum {
    AirFileExtNone = 0,
    AirFileExtText,
    AirFileExtImageJPEG,
    AirFileExtImagePNG,
    AirFileExtVideo,
    AirFileExtBinaryDat,
    AirFileExtBinaryExe,
    AirFileExtOthers,
} AirFileExt;

@interface AirFile : NSObject

@property (nonatomic) AirFileType fileType;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic) AirFileExt fileExt;// for file
@property (nonatomic) int fileCount;// for folder
//@property (nonatomic) AirFile *firstFile;// for folder

- (id)init;
- (id)initWithItem:(FAItem*)item;
- (id)initWithPath:(NSString*)path;
- (id)initWithFilename:(NSString*)name ext:(NSString*)ext;
- (NSData*)getFile;

@end
