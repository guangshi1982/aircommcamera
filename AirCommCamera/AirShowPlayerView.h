//
//  AirShowPlayerView.h
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/30.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AirShowPlayerView : UIView

+ (Class)layerClass;
- (AVPlayer*)player;
- (void)setPlayer:(AVPlayer *)player;

@end
