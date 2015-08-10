//
//  AirShowManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AirShowManager : NSObject

+(AirShowManager*)getInstance;
//- (void)setSoundPath:(NSString*)soundPath showPath:(NSString*)showPath;
- (void)createSlideShowWithImages:(NSArray *)images sound:(NSString*)soundPath show:(NSString*)showPath;
- (UIImage*)thumbnailOfVideo:(NSString*)videoPath;

@end
