//
//  AirPlayerViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/27.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

class AirPlayerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    let identifierAirFrameCell = "AirFrameCell"
    var itemStatusContext = "status"
    let tracksKey = "tracks"
    
    @IBOutlet weak var airPlayerView: AirPlayerView!
    @IBOutlet weak var airFrameCollectionView: UICollectionView!
    @IBOutlet weak var playButton: UIButton!
    var player: AVPlayer?
    var playerItem: AVPlayerItem?
    var airFrame: [AirFrame] = []
    var videoPath: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.playerItem?.removeObserver(self, forKeyPath: itemStatusContext)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == self.itemStatusContext {
            if self.player?.status == AVPlayerStatus.ReadyToPlay {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.syncUI()
                })
            }
            
            return
        }
        
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        
        return
    }
    
    // MARK: -UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airFrame.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.identifierAirFrameCell, forIndexPath: indexPath) as! AirFrameCell
        
        return cell
    }
    
    func updateVideo() {
        if (self.videoPath != nil) {
            self.loadAssetFromFile()
        }
    }
    
    @IBAction func play(sender: AnyObject) {
        self.player?.play()
    }
    
    private func loadAssetFromFile() {
        let videoUrl: NSURL = NSURL.fileURLWithPath(self.videoPath!)
        let asset: AVURLAsset = AVURLAsset(URL: videoUrl)
        
        asset.loadValuesAsynchronouslyForKeys([self.tracksKey]) { () -> Void in
            var error: NSError? = nil
            let status: AVKeyValueStatus = asset.statusOfValueForKey(self.tracksKey, error: &error)
            
            if (status == AVKeyValueStatus.Loaded) {
                self.playerItem = AVPlayerItem(asset: asset)
                self.playerItem?.addObserver(self, forKeyPath: self.itemStatusContext, options: NSKeyValueObservingOptions.Initial, context: nil)
                /*[[NSNotificationCenter defaultCenter] addObserver:self
                    selector:@selector(playerItemDidReachEnd:)
                name:AVPlayerItemDidPlayToEndTimeNotification
                object:self.playerItem];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];*/
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemDidReachEnd:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.playerItem)
                self.player = AVPlayer(playerItem: self.playerItem!)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.airPlayerView.player = self.player!
                    self.airPlayerView.setVideoFillMode(AVLayerVideoGravityResizeAspectFill)
                })
            } else {
                print("The asset's tracks were not loaded:\(error?.localizedDescription)")
            }
            
        }
    }
    
    private func syncUI() {
        if ((self.player?.currentItem != nil) &&
            (self.player?.currentItem?.status == AVPlayerItemStatus.ReadyToPlay)) {
                self.playButton.enabled = true
        } else {
            self.playButton.enabled = false
        }
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        self.player?.seekToTime(kCMTimeZero)
    }
}
