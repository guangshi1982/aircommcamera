//
//  AirFileManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/28.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AirFile.h"
#import "AirImage.h"

@class AirFileManager;

@protocol AirFileManagerDelegate <NSObject>

@optional
- (void)airFileManager:(AirFileManager*)manager isConnected:(BOOL)connection;
- (void)airFileManager:(AirFileManager*)manager requestedLatestImage:(AirImage*)image;

@end

// todo: rename to AirCameraManager
@interface AirFileManager : NSObject

// todo: reset in getInstance?
@property (nonatomic, weak) id<AirFileManagerDelegate> delegate;

+ (AirFileManager*)getInstance;
// todo:内部で定期的にconnectしているので、不要かも
- (void)connectWithRetryCount:(int)retryCount;
- (void)connect:(NSTimer*)timer;
- (BOOL)isConnected;
- (void)setRootPath:(NSString*)path;
- (NSArray*)foldersAtDirectory:(NSString*)path;
- (NSArray*)filesAtDirectory:(NSString*)path;
- (NSArray*)imagesAtDirectory:(NSString*)path;
- (int)latestImageIndex;
- (NSArray*)latestFolderImages;
- (AirImage*)latestImage;
- (void)requestLatestImage;
- (AirImage*)latestImageAt:(int)index;
- (void)requestLatestImageAt:(int)index;
- (NSArray*)latestImagesStartAt:(int)startIndex;
- (void)requestLatestImagesStartAt:(int)index;
- (NSArray*)filesAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (int)fileCountAtDirectory:(NSString*)path;
- (int)fileCountAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (AirFile*)firstFileAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (NSData*)getFileData:(NSString*)path;
- (NSData*)getPreviewData;

@end
