//
//  AirPreviewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/27.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit
import AVKit

class AirPreviewController: AVPlayerViewController {
    var previewPath: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let url: NSURL = NSURL.fileURLWithPath(self.previewPath!)
        self.player = AVPlayer(URL: url)
    }
}
