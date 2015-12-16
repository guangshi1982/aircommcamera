//
//  AirFileManagerViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/10/18.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

@objc protocol AirFileManagerViewDelegate: NSObjectProtocol {
    
    optional func airFileManagerViewController(airFileManagerViewController: AirFileManagerViewController, didFetchAirFiles airFiles: [AirFile])
    
    optional func airFileManagerViewControllerDidCancel(airFileManagerViewController: AirFileManagerViewController)
}

// Photo/FlashAir/SNS上のFileを管理??
class AirFileManagerViewController: UIViewController {
    
    weak var delegate: AirFileManagerViewDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

}
