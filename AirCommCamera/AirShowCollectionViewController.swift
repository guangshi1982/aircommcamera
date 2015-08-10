//
//  AirShowCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

let reuseIdentifier_airshow = "AirShowCell"

class AirShowCollectionViewController: UICollectionViewController {
    
    var airshowMan: AirShowManager?
    var airshowPath: String?
    var airshowFlolder: String = "/airshow"
    //var airshowFlolder: String = "/airmovie" //test
    var airshowFiles: [AnyObject]? = []
    var airshowCount: Int = 0;
    var seletectPath: NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // memo:不要(storyboardでIDを指定したから？)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier_airshow)

        // Do any additional setup after loading the view.
        self.airshowMan = AirShowManager()
        //self.airshowPath = FileManager.getSubDirectoryPath("/airshow")
        //self.airshowPath = FileManager.getSubDirectoryPath("/airmovie") // test
        
        // update by event in which show created
        self.airshowFiles = FileManager.getFilePathsInSubDir(self.airshowFlolder)
        self.airshowCount = Int(FileManager.getFileCountInSubDir(self.airshowFlolder))
        //self.airshowCount = Int(FileManager.getFileCountInFolder(self.airshowPath))
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        println("identifier: \(segue.identifier)")
        if segue.identifier == "AirShowPlayer" {
            let cell = sender as! AirShowCollectionViewCell
            let airshowPlayerController = segue.destinationViewController as! AirShowPlayerViewController
            airshowPlayerController.videoPath = cell.airshowPath
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airshowCount
        //return 0 // test
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier_airshow, forIndexPath: indexPath) as! AirShowCollectionViewCell
        
        // Configure the cell
        // todo:nil check
        let videoPath = self.airshowFiles?[indexPath.row] as! String
        let thumbnail: UIImage? = self.airshowMan!.thumbnailOfVideo(videoPath)
        if (thumbnail != nil) {
            println("thumbnail nil")
            cell.thumbnailImageView!.image = thumbnail
            cell.airshowPath = videoPath
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    // MARK: Action
    
    @IBAction func selectFolder(sender: AnyObject) {
        
    }
    
    @IBAction func airshowAction(sender: AnyObject) {
        // test
        var airShowMan: AirShowManager = AirShowManager()
        //let soundPath = FileManager.getPathWithFileName("bgm.mp3", fromFolder: "/sound")
        let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
        let showPath = FileManager.getPathWithFileName("1.mov", fromFolder: "/airshow")
        var images: NSMutableArray = NSMutableArray()
        images.addObject(UIImage(named: "1.jpg")!)
        images.addObject(UIImage(named: "2.jpg")!)
        images.addObject(UIImage(named: "3.jpg")!)
        //airShowMan.setSoundPath(soundPath, showPath: showPath)
        airShowMan.createSlideShowWithImages(images as [AnyObject], sound:soundPath, show:showPath)
    }

}
