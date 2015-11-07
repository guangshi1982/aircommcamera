//
//  AirFile.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/15.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirFile.h"
#import "AirFileManager.h"

@implementation AirFile

- (id)init
{
    if (self = [super init]) {
        
    }
    
    return self;
}

- (id)initWithItem:(FAItem*)item
{
    if (self = [super init]) {
        AirFileManager *airFileMan = [AirFileManager getInstance];
        _filePath = item.path;
        _fileName = item.filename;
        if (item.isDirectory) {
            _fileType = AirFileTypeFolder;
            _fileCount = [airFileMan fileCountAtDirectory:_filePath];
        } else {
            _fileType = AirFileTypeFile;
            _fileCount = 1;
            _fileExt = [self fileExtFormString:item.extension];
        }
    }
    
    return self;
}

- (id)initWithPath:(NSString*)path
{
    if (self = [super init]) {
        _filePath = path;
        _fileName = [self getFileNameFromPath:path];
    }
    
    return self;
}

- (id)initWithFilename:(NSString*)name ext:(NSString*)ext
{
    if (self = [super init]) {
        _fileName = name;
        _fileType = AirFileTypeFile;
        _fileExt = [self fileExtFormString:ext];
    }
    
    return self;
}

- (NSData*)getFile
{
    AirFileManager *airFileMan = [AirFileManager getInstance];
    
    return [airFileMan getFileData:_filePath];
}

- (NSString*)getFileNameFromPath:(NSString*)path
{
    NSString *fileName = nil;
    
    NSString *lastComp = [path lastPathComponent];
    if (lastComp != nil) {
        fileName = [lastComp stringByDeletingPathExtension];
    }
    
    return fileName;
}

- (AirFileExt)fileExtFormString:(NSString*)strExt
{
    AirFileExt fileExt = AirFileExtNone;
    
    if ([strExt compare:@"JPG"] == NSOrderedSame) {
        fileExt = AirFileExtImageJPEG;
    }
    
    return fileExt;
}

@end
