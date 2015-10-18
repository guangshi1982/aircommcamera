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

@interface AirFileManager : NSObject

+ (AirFileManager*)getInstance;
- (BOOL)isConnected;
- (NSArray*)foldersAtDirectory:(NSString*)path;
- (NSArray*)filesAtDirectory:(NSString*)path;
- (NSArray*)imagesAtDirectory:(NSString*)path;
- (NSArray*)filesAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (int)fileCountAtDirectory:(NSString*)path;
- (int)fileCountAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (AirFile*)firstFileAtDirectory:(NSString*)path fileExt:(NSString*)ext;
- (NSData*)getFileData:(NSString*)path;

@end
