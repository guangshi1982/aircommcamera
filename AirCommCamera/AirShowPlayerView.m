//
//  AirShowPlayerView.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/30.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirShowPlayerView.h"

@interface AirShowPlayerView ()

@property (nonatomic) AVPlayer *player;

@end

@implementation AirShowPlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
