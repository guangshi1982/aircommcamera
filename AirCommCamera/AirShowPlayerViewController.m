//
//  AirShowPlayerViewController.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/30.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirShowPlayerViewController.h"
#import "AirShowPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext = @"status";

@class AirShowPlayerView;

@interface AirShowPlayerViewController ()

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
//@property (nonatomic) AirShowPlayerView *playerView;
@property (nonatomic, weak) IBOutlet AirShowPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@end


@implementation AirShowPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self loadAssetFromFile];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // memo:need to remove!
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)loadAssetFromFile {
    NSURL *videoUrl = [NSURL fileURLWithPath:_videoPath];
    // create asset
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    NSString *tracksKey = @"tracks";
    // load asset tracks
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
     ^{
         // The completion block goes here.
         NSError *error;
         AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
         if (status == AVKeyValueStatusLoaded) {// loaded for playing
             // create player item with asset and manager asset tracks with item tracks
             // or create with url (how about status??)
             self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
             // ensure that this is done before the playerItem is associated with the player
             [self.playerItem addObserver:self forKeyPath:@"status"
                                  options:NSKeyValueObservingOptionInitial
                                  context:&ItemStatusContext];
             [[NSNotificationCenter defaultCenter] addObserver:self
                                                      selector:@selector(playerItemDidReachEnd:)
                                                          name:AVPlayerItemDidPlayToEndTimeNotification
                                                        object:self.playerItem];
             self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
             dispatch_async(dispatch_get_main_queue(),
                            ^{
                                // AirShowPlayerView.hをincludeしないと、エラーが発生！？
                                [(AirShowPlayerView*)_playerView.layer setPlayer:self.player];
                            });
         } else {
             // You should deal with the error appropriately.
             NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
         }
     }];
}

// ボタンの状態をプレーヤーの状態と同期
- (void)syncUI {
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

// プレーヤーアイテムのステータス変更を監視
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    NSLog(@"observeValueForKeyPath:%@", keyPath);
    
    if (context == &ItemStatusContext) {
        NSLog(@"player.status:%ld", (long)self.player.status);
        if (self.player.status == AVPlayerStatusReadyToPlay) {
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                               [self syncUI];
                           });
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"playerItemDidReachEnd");
    [self.player seekToTime:kCMTimeZero];
}

- (IBAction)play:sender {
    [self.player play];
}


@end
