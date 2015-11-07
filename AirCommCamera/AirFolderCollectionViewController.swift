//
//  AirFolderCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit


class AirFolderCollectionViewController: UICollectionViewController {
    
    let identifierAirFolderCell = "AirFolderCell"
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirShowCollectionViewController = "AirShowCollectionViewController"
    
    var parentDir: String?
    var airFolders: [AirFile] = []
    var airFileMan: AirFileManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirFolderCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // memo:不要(storyboardでIDを指定したから？)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: identifierAirFolderCell)

        // Do any additional setup after loading the view.
        
        // init
        //self.folders = NSMutableArray()
        self.airFileMan = AirFileManager.getInstance()
        
        // todo:async
        let airFiles: [AirFile]? = self.airFileMan?.foldersAtDirectory(self.parentDir) as? [AirFile]
        if (airFiles != nil) {
            print("airFiles:\(airFiles?.count)")
            self.airFolders = airFiles!
        }
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
        print("prepareForSegue[AirImageCollection]")
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == self.identifierAirImageCollectionViewController {
            let airImageCollectionViewController = segue.destinationViewController as! AirImageCollectionViewController
            let cell = sender as! AirFolderCell
            airImageCollectionViewController.parentDir = cell.folderPath
            airImageCollectionViewController.pathType = 1
            //airImageCollectionViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airFolders.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirFolderCell, forIndexPath: indexPath) as! AirFolderCell
    
        // Configure the cell
        let airFile: AirFile = self.airFolders[indexPath.row]
        let folderPath = airFile.filePath
        let firstAirFile: AirFile? = airFileMan?.firstFileAtDirectory(folderPath, fileExt: ".JPG")
        if (firstAirFile != nil) {
            cell.folderPath = folderPath
            let fileData: NSData? = self.airFileMan?.getFileData(firstAirFile!.filePath)
            let image: UIImage? = UIImage(data: fileData!)
            cell.folderImageView1.image = image
            cell.folderImageView2.image = image
            cell.folderImageView3.image = image
            
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
    
    @IBAction func cancelAction(sender: AnyObject) {
        //self.performSegueWithIdentifier(self.identifierAirShowCollectionViewController, sender: nil)
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismiss AirFolderCollectionViewController")
        })
    }
}
