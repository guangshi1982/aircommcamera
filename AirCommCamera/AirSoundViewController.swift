//
//  AirSoundViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/12.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class AirSoundViewController: AirPlayerViewController, AirShowObserver {

    let identifierAirShowCollectionViewController = "AirShowCollectionViewController"
    
    var airShowMan: AirShowManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirSoundViewController viewDidLoad")

        // Do any additional setup after loading the view.
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("prepareForSegue[add sound]")
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == self.identifierAirShowCollectionViewController {
            //let airShowCollectionViewController = segue.destinationViewController as! AirShowCollectionViewController
        }
    }

    // MARK: AirShowObserver
    
    func progress(progress: Float, inCreatingShow showPath: String!) {
        // todo:progress bar
        print("AddingSoundToMovie progress:\(progress)")
        
        if (progress == 100) {
            // todo: rename tmp folder and save to show folder
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let dstPath = "airshow/" + dateFormatter.stringFromDate(now)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath("airfolder/tmp", toPath: dstPath)
            [self.performSegueWithIdentifier(self.identifierAirShowCollectionViewController, sender: dstPath)]
        }
    }
    
    // MARK: Action
    
    @IBAction func makeAction(sender: AnyObject) {
        // test
        let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
        let airSound: AirSound = AirSound(path: soundPath)
        let airMovie: AirMovie = AirMovie(path: self.videoPath)
        let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: "airfolder/tmp/show")
        self.airShowMan!.createAirShowFromAirMovie(airMovie, withAirSound: airSound, show: showPath)
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
    }
    
    @IBAction func editAction(sender: AnyObject) {
        
    }
    
    @IBAction func addAction(sender: AnyObject) {
        
    }
}