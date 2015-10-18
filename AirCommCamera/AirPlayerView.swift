//
//  AirPlayerView.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/27.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit
import AVFoundation

// create subview of UIView hosting an AVPlayerLayer.
class AirPlayerView: UIView {

    // return layer of AVPlayerLayer instead of CALayer of UIView default.
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer {
        get {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            return layer.player!
        }
        set(newValue) {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            layer.player = newValue
        }
    }
    
    // AVLayerVideoGravityResizeAspect is default
    func videoFillMode() -> String {
        let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
        
        return layer.videoGravity
    }
    
    func setVideoFillMode(fillMode: String) {
        let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
        
        layer.videoGravity = fillMode
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
