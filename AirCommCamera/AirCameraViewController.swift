//
//  AirCameraViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/10/13.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

class AirCameraViewController: UIViewController {
    
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirImageNavigationController = "AirImageNavigationController"
    
    @IBOutlet weak var capturedImageView: UIImageView!
    
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
    
    
    // MARK: - Action
    
    @IBAction func syncWithCamera(sender: AnyObject) {
        // test
        let folderPath = "/DCIM/IMGS/FLD016"
        
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = folderPath
        // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
        //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
        
        // todo:custom segue
        // memo: not airimagecontroller
        self.presentViewController(airNavigationController, animated: true) { () -> Void in
            print("AirImageCollectionViewController")
        }
    }
    
    @IBAction func showCapturedImages(sender: AnyObject) {
        // test
        FileManager.createSubFolder("airimage/aircamera/tmp")
        for (var i = 1; i <= 3; i++) {
            let imageName = String(format: "%d.jpg", i)
            let image = UIImage(named: imageName)
            let data = UIImageJPEGRepresentation(image!, 1)
            FileManager.saveData(data, toFile: imageName, inFolder: "airimage/aircamera/tmp")
        }
        
        //let folderPath = FileManager.getSubDirectoryPath("airimage/tmp")
        let folderPath = "airimage/aircamera/tmp"
        
        //let airImageCollectionViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AirImageCollectionViewController") as! AirImageCollectionViewController
        //airImageCollectionViewController.parentDir = folderPath
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = folderPath
        airImageCollectionViewController.pathType = 1
        // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
        //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
        
        // todo:custom segue
        // memo: not airimagecontroller
        self.presentViewController(airNavigationController, animated: true) { () -> Void in
            print("AirImageCollectionViewController")
        }
    }
    
    @IBAction func closeCamera(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
    
    @IBAction func unwindBackToAirCameraController(unwindSegue: UIStoryboardSegue) {
        // todo:unwindSegue.sourceViewController.isKindOfClass()
    }
}



