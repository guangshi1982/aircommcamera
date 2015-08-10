//
//  AirFileManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/28.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AirFileManager : NSObject

+ (AirFileManager*)getInstance;
- (NSArray*)foldersAtDirectory:(NSString*)path;
- (NSArray*)filesAtDirectory:(NSString*)path fileType:(NSString*)type;
- (NSString*)firstFileAtDirectory:(NSString*)path fileType:(NSString*)type;

@end
