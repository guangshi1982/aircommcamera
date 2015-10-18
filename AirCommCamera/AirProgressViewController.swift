//
//  AirProgressViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/10/11.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit
import MBCircularProgressBar


class AirProgressViewController: UIViewController {
    
    @IBOutlet weak var airProgressView: MBCircularProgressBarView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.airProgressView.value = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func updateProgress(progress: CGFloat) {
        print("updateProgress progress:\(progress)")
        self.airProgressView.value = progress
    }

}
