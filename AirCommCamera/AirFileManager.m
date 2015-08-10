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
        _flashAir = [[FAFlashAir alloc] init];
    }
    
    return self;
}

- (NSArray*)foldersAtDirectory:(NSString*)path
{
    NSError *error = nil;
    NSMutableArray *folders = [[NSMutableArray alloc] init];
    
    // Get file list
    NSArray *fileList = [_flashAir getFileListWithDirectory:path error:&error];
    if (error){
        NSLog(@"foldersAtDirectory %@\n",error);
        return folders;
    }
    
    for (int i = 0; i < fileList.count; i++) {
        FAItem *item = (FAItem*)[fileList objectAtIndex:i];
        if (item.isDirectory) {
            [folders addObject:item.path];
        }
    }
    
    return folders;
}

- (NSArray*)filesAtDirectory:(NSString*)path fileType:(NSString*)type
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
        if ([item hasExtension:type]) {
            [files addObject:item.path];
        }
    }
    
    return files;
}

- (NSString*)firstFileAtDirectory:(NSString*)path fileType:(NSString*)type
{
    NSError *error = nil;
    NSString *file = nil;
    
    NSArray *fileList = [self filesAtDirectory:path fileType:type];
    if (fileList != nil) {
        for (int i = 0; i < fileList.count; i++) {
            FAItem *item = (FAItem*)[fileList objectAtIndex:i];
            if ([item hasExtension:type]) {
                file = item.path;
                break;
            }
        }
    }
    
    if (file == nil) {
        file = [_flashAir getControlImage:&error];
    }
    
    return file;
}

@end
