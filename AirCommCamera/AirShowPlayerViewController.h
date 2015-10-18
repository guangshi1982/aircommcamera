//
//  AirShowPlayerViewController.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/30.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AirShowPlayerViewController : UIViewController

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *videoTitle;
@property (nonatomic) UIImage *videoThumbnail;

- (void)updateVideo;

@end
