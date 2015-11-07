//
//  AirFileManager.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/28.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirFileManager.h"
#import "FAFlashAir.h"
#import "FAItem.h"

// todo: check connection
@interface AirFileManager()

@property (nonatomic) FAFlashAir *flashAir;

@end

@implementation AirFileManager

+ (AirFileManager*)getInstance
{
    static AirFileManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [AirFileManager new];
    });
    
    return sharedInstance;
}

- (id)init
{
    if (self = [super init]) {
        //_flashAir = [[FAFlashAir alloc] initWithHostname:@"aircard.local"];
        _flashAir = [[FAFlashAir alloc] initWithHostname:@"192.168.0.1"];
    }
    
    return self;
}

- (BOOL)isConnected
{
    BOOL ret = NO;
    
    if (_flashAir) {
        NSError *error = nil;
        int version = [_flashAir getFirmwareVersion:&error];
        if (version != -1 && error != nil) {
            ret = YES;
        } else if (error != nil) {
            NSLog(@"isConnected %@\n", error);
        }
    }
    
    return ret;
}

- (NSArray*)foldersAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *folders = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"foldersAtDirectory %@\n", error);
        return folders;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && item.isDirectory) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [folders addObject:airFile];
        }
    }
    
    return folders;
}

// folders and files
- (NSArray*)filesAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n",error);
        return files;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [files addObject:airFile];
        }
    }
    
    return files;
}

- (NSArray*)imagesAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *images = [[NSMutableArray alloc] init];
    NSString *ext = @"JPG";
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return images;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && [item hasExtension:ext]) {
            AirImage *airImage = [[AirImage alloc] initWithItem:item];
            [images addObject:airImage];
        }
    }
    
    return images;
}

- (NSArray*)filesAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    NSMutableArray *files = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return files;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && [item hasExtension:ext]) {
            AirFile *airFile = [[AirFile alloc] initWithItem:item];
            [files addObject:airFile];
        }
    }
    
    return files;
}

- (int)fileCountAtDirectory:(NSString*)path
{
    NSError *error = nil;
    int fileCount = 0;
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return 0;
    }
    
    fileCount = (int)fileList.count;
    
    return fileCount;
}

- (int)fileCountAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    int fileCount = 0;
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"filesAtDirectory %@\n", error);
        return 0;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item != nil && [item hasExtension:ext]) {
            fileCount++;
        }
    }
    
    return fileCount;
}

- (AirFile*)firstFileAtDirectory:(NSString*)path fileExt:(NSString*)ext
{
    NSError *error = nil;
    AirFile *airFile = nil;
    
    NSArray *fileList = [self filesAtDirectory:path fileExt:ext];
    if (fileList != nil && fileList.count > 0) {
        airFile = fileList[0];
    }
    
    if (airFile == nil) {
        NSString *contImage = [_flashAir getControlImage:&error];
        airFile = [[AirFile alloc] init];
        airFile.fileType = AirFileTypeFile;
        airFile.filePath = contImage;
    }
    
    return airFile;
}

- (NSData*)getFileData:(NSString*)path
{
    NSError *error = nil;
    NSData *fileData = nil;
    
    fileData = [_flashAir getFile:path error:&error];
    if (error) {
        NSLog(@"getFileData %@\n", error);
        return nil;
    }
    
    return fileData;
}

@end
