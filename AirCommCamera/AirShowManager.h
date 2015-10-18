//
//  AirShowManager.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AirImage.h"
#import "AirMovie.h"
#import "AirSound.h"
#import "AirShow.h"

@protocol AirShowObserver <NSObject>

@optional
- (void)progress:(float)progress inCreatingMovies:(NSString*)movieFolder;
- (void)progress:(float)progress inAddingTextToMovie:(NSString*)moviePath;// connectingに統一
- (void)progress:(float)progress inConnectingMovies:(NSString*)moviePath;
//- (void)progress:(float)progress inAddingSoundToMovie:(NSString*)moviePath;
- (void)progress:(float)progress inCreatingShow:(NSString*)showPath;
- (void)progress:(float)progress inProcessingShow:(NSString*)showPath;

@end

@interface AirShowManager : NSObject

@property (nonatomic, weak) id<AirShowObserver> observer;

+ (AirShowManager*)getInstance;
// todo:画像処理追加
- (void)createAirMovieWithAirImage:(AirImage*)airImage movie:(NSString*)moviePath;
- (void)createAirMoviesWithAirImages:(NSArray*)airImages movies:(NSString*)movieFolder;
- (void)connectAirMovies:(NSArray*)airMovies movie:(NSString*)moviePath;
//- (void)addSound:(AirSound*)airSound toMovie:(AirMovie*)airMovie;
- (void)createAirShowFromAirMovie:(AirMovie*)airMovie withAirSound:(AirSound*)airSound show:(NSString*)showPath;
// create with images automatically
- (void)createShowWithAirImages:(NSArray*)airImages;

//- (void)setSoundPath:(NSString*)soundPath showPath:(NSString*)showPath;
- (void)createSlideShowWithImages:(NSArray *)images sound:(NSString*)soundPath show:(NSString*)showPath;
- (UIImage*)thumbnailOfVideo:(NSString*)videoPath;

@end
