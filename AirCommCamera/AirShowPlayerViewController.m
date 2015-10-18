//
//  AirShowPlayerViewController.m
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/30.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

#import "AirShowPlayerViewController.h"
#import "AirShowPlayerView.h"
#import "AirFrameCell.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext = @"status";
static NSString *identifierAirFrameCell = @"AirFrameCell";

@class AirShowPlayerView;

@interface AirShowPlayerViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate>

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
//@property (nonatomic) AirShowPlayerView *playerView;
@property (nonatomic) NSMutableArray *airFrames;
@property (nonatomic, weak) IBOutlet AirShowPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (nonatomic, weak) IBOutlet UICollectionView *airFrameCollectionView;

@end


@implementation AirShowPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _airFrames = [[NSMutableArray alloc] init];
    /*
    if (_videoPath != nil) {
        NSLog(@"videoPath:%@", _videoPath);
        [self loadAssetFromFile];
    }*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //[self loadAssetFromFile];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSLog(@"viewDidDisappear");
    
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

#pragma UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _airFrames.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AirFrameCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifierAirFrameCell forIndexPath:indexPath];
    
    return cell;
}

- (void)updateVideo {
    if (_videoPath != nil) {
        NSLog(@"videoPath:%@", _videoPath);
        [self loadAssetFromFile];
    }
}

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

- (void)shareCompleted:(NSString*)activityType completed:(BOOL)completed {
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"playerItemDidReachEnd");
    [self.player seekToTime:kCMTimeZero];
}

- (IBAction)play:sender {
    [self.player play];
}

- (IBAction)shareAction:(id)sender {
    NSArray *activityItems = [NSArray arrayWithObjects:_videoTitle, _videoThumbnail, nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
        NSLog(@"completionWithItemsHandler:%@", activityType);
    };
    
    [self presentViewController:activityViewController animated:true completion:^{
        NSLog(@"activityViewController");
    }];
     
}

- (IBAction)deleteAction:(id)sender {
    UIAlertController *actionSheetController = [UIAlertController alertControllerWithTitle:nil message:@"Delete this show?" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSLog(@"Deleted");
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSLog(@"Canceled");
    }];
    
    [actionSheetController addAction:delete];
    [actionSheetController addAction:cancel];
    [self presentViewController:actionSheetController animated:true completion:^{
        NSLog(@"actionSheetController");
    }];
}

- (IBAction)editAction:(id)sender {
}

@end
