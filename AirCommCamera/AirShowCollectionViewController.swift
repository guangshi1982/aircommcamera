//
//  AirShowCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit
import Social
import QBImagePickerController

class AirShowCollectionViewController: UICollectionViewController, AirShowEditViewControllerDelegate, QBImagePickerControllerDelegate, AirShowObserver, AirFileManagerDelegate {
    
    let identifierAirShowCell = "AirShowCell"
    let identifierAirShowEditViewController = "AirShowEditViewController"
    let identifierAirPreviewController = "AirPreviewController"
    let identifierAirLocalCameraViewController = "AirLocalCameraViewController"
    let identifierAirCameraViewController = "AirCameraViewController"
    let identifierAirFolderNavigationController = "AirFolderNavigationController"
    let identifierAirFolderCollectionViewController = "AirFolderCollectionViewController"
    let identifierAirActionNavigationController = "AirActionNavigationController"
    let identifierAirShowNavigationController = "AirShowNavigationController"
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirImageNavigationController = "AirImageNavigationController"
    
    let connectionMaxCount = 3;
    
    var airShowMan: AirShowManager?
    var airFileMan: AirFileManager?
    var airShowPath: String? // new air show path
    var airShowFlolder: String = "airshow"
    //var airShowFlolder: String = "airmovie" //test
    // todo: [AirShow]
    var airShows: [String] = []
    var seletectPath: NSIndexPath?
    
    var airCameraConnTimer: NSTimer?
    var connInterval: NSTimeInterval = 3
    var connCount: Int = 0
    var isConnected: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirShowCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // memo:不要(storyboardでIDを指定したから)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier_airshow)

        // Do any additional setup after loading the view.
        self.airShowMan = AirShowManager.getInstance()
        self.airFileMan = AirFileManager.getInstance()
        self.airFileMan?.delegate = self
        
        //self.airCameraConnTimer = NSTimer.scheduledTimerWithTimeInterval(self.connInterval, target: self, selector: Selector("connectToCamera:"), userInfo: nil, repeats: true)
        
        // todo:update by event in which show created
        self.airShows = FileManager.getFilePathsInSubDir(self.airShowFlolder) as! [String]
        print("airShowCount:\(self.airShows.count)")
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
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == identifierAirShowEditViewController {
            let cell = sender as! AirShowCell
            let selectedIndexpath = self.collectionView?.indexPathForCell(cell)
            let airshowPlayerController = segue.destinationViewController as! AirShowEditViewController
            airshowPlayerController.delegate = self
            airshowPlayerController.videoPath = cell.airShowPath
            airshowPlayerController.airShowFolder = self.airShows[selectedIndexpath!.row]
            
            //airshowPlayerController.updateVideo()
        } else if segue.identifier == identifierAirPreviewController {
            let cell = sender as! AirShowCell
            let airPreviewController = segue.destinationViewController as! AirPreviewController
            airPreviewController.previewPath = cell.airShowPath
        } else if segue.identifier == identifierAirCameraViewController {
            
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(self.airShows.count)
        return self.airShows.count
        //return 0 // test
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirShowCell, forIndexPath: indexPath) as! AirShowCell
        
        // Configure the cell
        // todo:nil check
        let showFolder = self.airShows[indexPath.row] 
        let showPath = showFolder + "/" + "show/airshow.mov"
        print(showPath)
        let thumbnail: UIImage? = self.airShowMan!.thumbnailOfVideo(showPath, withSize: (cell.thumbnailImageView?.bounds.size)!)
        if (thumbnail != nil) {
            cell.thumbnailImageView!.image = thumbnail
            cell.airShowPath = showPath
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
    
    // todo: delete
    func connectToCamera(timer: NSTimer) {
        self.isConnected = (self.airFileMan?.isConnected())!
        if (self.isConnected || self.connCount >= self.connectionMaxCount) {
            if (self.isConnected) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.navigationItem.title = "Connected"
                })
            }
            if ((self.airCameraConnTimer?.valid) != nil) {
                self.airCameraConnTimer?.invalidate()
            }
        } else {
            self.connCount++
        }
    }
    
    // MARK: AirFileManagerDelegate
    
    func airFileManager(manager: AirFileManager!, isConnected connection: Bool) {
        var connState = "Disconnected"
        
        self.isConnected = connection
        
        if (connection) {
            connState = "Connected"
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.navigationItem.title = connState
        })
    }
    
    // MARK: AirShowEditViewControllerDelegate
    
    func airShowEditViewController(airShowEditViewController: AirShowEditViewController, didFinishEditingAirshowAtPath path: String) {
        
    }
    
    func airShowEditViewController(airShowEditViewController: AirShowEditViewController, didFinishDeletingAirshowAtPath path: String) {
        
        for (var i = 0; i < self.airShows.count; i++) {
            if self.airShows[i] == path {
                self.airShows.removeAtIndex(i)
                let deleteIndexpath = NSIndexPath(forItem: i, inSection: 0)
                self.collectionView?.deleteItemsAtIndexPaths([deleteIndexpath])
                break;
            }
        }
    }
    
    // MARK: QBImagePickerControllerDelegate
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        print("didFinishPickingAssets")
        print("count of assets : \(assets.count)")
        
        /*
        for var i = 0; i < assets.count; i++ {
            var asset: PHAsset = assets[i] as! PHAsset
            if (asset.mediaType == PHAssetMediaType.Image) {
                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: nil, resultHandler: { (imageData: NSData!, dataUTI: String!, orientation: UIImageOrientation, info: [NSObject : AnyObject]!) -> Void in
                    let image: UIImage! = UIImage(data: imageData)
                    if (image != nil) {
                        dispatch_async(self.movieQueue!, { () -> Void in
                            // create movie
                        })
                    }
                })
            }
        }*/
        var airImages: [AirImage] = []
        let requestOption: PHImageRequestOptions = PHImageRequestOptions()
        // memo:同期
        requestOption.synchronous = true
        for var i = 0; i < assets.count; i++ {
            let asset: PHAsset = assets[i] as! PHAsset
            if (asset.mediaType == PHAssetMediaType.Image) {
                print("request image start")
                PHImageManager.defaultManager().requestImageDataForAsset(asset, options: requestOption, resultHandler: { (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                    print("orientation:\(orientation.rawValue)")
                    let image: UIImage? = UIImage(data: imageData!)
                    if (image != nil) {
                        // todo: add Date/Time/Location info
                        let airImage: AirImage = AirImage(filename: String(format: "%d", i + 1), ext: "JPG")
                        airImage.image = image
                        airImages.append(airImage)
                    }
                })
                print("request image end")
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissImagePickerController")
            
            #if false
            // memo:一旦前のviewをdismissする必要がある
            let airShowNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirShowNavigationController) as! UINavigationController
            let airImageSelectedViewController: AirImageSelectedViewController = airShowNavigationController.topViewController as! AirImageSelectedViewController
            airImageSelectedViewController.airImages = airImages
            
            self.presentViewController(airShowNavigationController, animated: true) { () -> Void in
                print("AirShowNavigationController")
            }
                
            #else // test
            
                //let airImageCollectionViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AirImageCollectionViewController") as! AirImageCollectionViewController
                //airImageCollectionViewController.parentDir = folderPath
                let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
                let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
                airImageCollectionViewController.airImages = airImages
                airImageCollectionViewController.pathType = 2
                // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
                //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
                
                // todo:custom segue
                // memo: not airimagecontroller
                self.presentViewController(airNavigationController, animated: true) { () -> Void in
                    print("AirImageCollectionViewController")
                }
            #endif
        })
    }
    
    func qb_imagePickerControllerDidCancel(imagePickerController: QBImagePickerController!) {
        print("qb_imagePickerControllerDidCancel")
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, shouldSelectAsset asset: PHAsset!) -> Bool {
        print("shouldSelectAsset")
        return true
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didSelectAsset asset: PHAsset!) {
        print("didSelectAsset")
    }
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didDeselectAsset asset: PHAsset!) {
        print("didDeselectAsset")
    }
    
    // MARK: Action
    
    @IBAction func selectFolder(sender: AnyObject) {
        // test
        let airShowMan: AirShowManager = AirShowManager()
        
        /*
        //let soundPath = FileManager.getPathWithFileName("bgm.mp3", fromFolder: "sound")
        let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
        let showPath = FileManager.getPathWithFileName("1.mov", fromFolder: "airshow")
        var images: NSMutableArray = NSMutableArray()
        images.addObject(UIImage(named: "1.jpg")!)
        //images.addObject(UIImage(named: "2.jpg")!)
        //images.addObject(UIImage(named: "3.jpg")!)
        //airShowMan.setSoundPath(soundPath, showPath: showPath)
        airShowMan.createSlideShowWithImages(images as [AnyObject], sound:soundPath, show:showPath)
        */
        
        
        
        FileManager.deleteSubFolder("airfolder/tmp")
        FileManager.createSubFolder("airfolder/tmp/image/before")// original images
        FileManager.createSubFolder("airfolder/tmp/image/after")// for effect
        FileManager.createSubFolder("airfolder/tmp/movie") // transition or none (from images with effect). And connected movie named [airmovie.xxx]
        //FileManager.createSubFolder("airfolder/tmp/movie/before") // original movies from images with effect
        //FileManager.createSubFolder("airfolder/tmp/movie/after")// for transition
        //FileManager.createSubFolder("airfolder/tmp/movie/connected")
        FileManager.createSubFolder("airfolder/tmp/sound") // connected movie from movies (no sound)
        //FileManager.createSubFolder("airfolder/tmp/sound/before")
        //FileManager.createSubFolder("airfolder/tmp/sound/after")
        FileManager.createSubFolder("airfolder/tmp/show")
        //FileManager.createSubFolder("airfolder/tmp/show/before")
        //FileManager.createSubFolder("airfolder/tmp/show/after")
        
        let airImage: AirImage = AirImage()
        airImage.image = UIImage(named: "1.jpg")
        airImage.fileName = "1"
        let moviePath = FileManager.getPathWithFileName(String(format: "%@.mov", airImage.fileName), fromFolder: "airfolder/tmp/movie")
        airShowMan.createAirMovieWithAirImage(airImage, movie: String(format: "%@.mov", airImage.fileName), inFolder: "airfolder/tmp/movie")
        
    }
    
    @IBAction func createAirShow(sender: AnyObject) {
        
        // todo: create tmp folder[airfolder(TBD)] for creating image/movie/show
        //       rename tmp folder to new folder when success for creating
        //       delete when canceled or failed for creating
        FileManager.deleteSubFolder("airfolder/tmp")
        FileManager.createSubFolder("airfolder/tmp/image/before")// original images
        FileManager.createSubFolder("airfolder/tmp/image/after")// for effect
        FileManager.createSubFolder("airfolder/tmp/movie") // none effect(from images with ). And connected movie named [airmovie.xxx]
        FileManager.createSubFolder("airfolder/tmp/transform") // transition
        //FileManager.createSubFolder("airfolder/tmp/movie/before") // original movies from images with effect
        //FileManager.createSubFolder("airfolder/tmp/movie/after")// for transition
        //FileManager.createSubFolder("airfolder/tmp/movie/connected")
        FileManager.createSubFolder("airfolder/tmp/sound") // connected movie from movies (no sound)
        //FileManager.createSubFolder("airfolder/tmp/sound/before")
        //FileManager.createSubFolder("airfolder/tmp/sound/after")
        FileManager.createSubFolder("airfolder/tmp/show")
        //FileManager.createSubFolder("airfolder/tmp/show/before")
        //FileManager.createSubFolder("airfolder/tmp/show/after")
        

        // added in iOS8
        let actionSheet = UIAlertController(title: "Create slide show", message: "Select images from below", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let localCameraButtonAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("LocalCamera")
            
            let airLocalCameraViewController: AirLocalCameraViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirLocalCameraViewController) as! AirLocalCameraViewController
            
            self.presentViewController(airLocalCameraViewController, animated: true) { () -> Void in
                print("AirLocalCameraViewController")
            }
        }
        
        // todo:Add to LocalCamera and switch from LocalCamera (SegmentedControl)
        var airCameraTitle = "AirCamera"
        if (!self.isConnected) {
            airCameraTitle = "AirCamera(Disconnected)"
        }
        let airCameraButtonAction = UIAlertAction(title: airCameraTitle, style: UIAlertActionStyle.Default) { (action) -> Void in
            print("AirCamera")
            
            let airCameraViewController: AirCameraViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirCameraViewController) as! AirCameraViewController
            
            self.presentViewController(airCameraViewController, animated: true) { () -> Void in
                print("AirCameraViewController")
            }
        }
        
        let photosButtonAction = UIAlertAction(title: "Photos", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Photos")
            
            if (!QBImagePickerController.isAccessibilityElement()) {
                // alert
                print("Not accessible")
            }
            
            let imagePickerController = QBImagePickerController()
            imagePickerController.delegate = self
            imagePickerController.allowsMultipleSelection = true
            imagePickerController.minimumNumberOfSelection = 1
            imagePickerController.maximumNumberOfSelection = 50 // TBD
            imagePickerController.showsNumberOfSelectedAssets = true
            imagePickerController.numberOfColumnsInPortrait = 4
            imagePickerController.numberOfColumnsInLandscape = 7
            //var subtypes: [AnyObject] = []
            
            //imagePickerController.assetCollectionSubtypes = subtypes
            
            self.presentViewController(imagePickerController, animated: true, completion: { () -> Void in
                print("presentViewController")
            })
        }
        
        // todo:Add to AirFolder
        let snsButtonAction = UIAlertAction(title: "SNS", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("SNS")
        }
        
        // todo:Add to AirFolder
        let flashairButtonAction = UIAlertAction(title: "FlashAir", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("FlashAir")
            
            let airFolderNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirFolderNavigationController) as! UINavigationController
            let airFolderCollectionViewController: AirFolderCollectionViewController = airFolderNavigationController.topViewController as! AirFolderCollectionViewController
            airFolderCollectionViewController.parentDir = "/SD_WLAN"
            
            // memo: not folderviewcontroller
            self.presentViewController(airFolderNavigationController, animated: true) { () -> Void in
                print("AirFolderNavigationController")
            }
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
            //FileManager.deleteSubFolder("airfolder/tmp")
        }
        
        actionSheet.addAction(localCameraButtonAction)
        actionSheet.addAction(photosButtonAction)
        actionSheet.addAction(airCameraButtonAction)
        actionSheet.addAction(flashairButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }

    }
    
    @IBAction func shareAirShow(sender: AnyObject) {
        let showFolder = self.airShows[0] 
        let showPath = showFolder + "/" + "show/airshow.mov"
        let videoLink = NSURL(fileURLWithPath: showPath)
        //let items = ["test", videoLink]
        let items = [videoLink, "test"]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.setValue("Share video", forKey: "Subject")
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if (completed) {
                print("completed")
            }
        }
        
        self.presentViewController(activityViewController, animated: true) { () -> Void in
            print("UIActivityViewController")
        }
    }
    
    @IBAction func captureAirCamera(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Capture images", message: "Select a camera", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let localCameraButtonAction = UIAlertAction(title: "LocalCamera", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("LocalCamera")
            
            let airLocalCameraViewController: AirLocalCameraViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirLocalCameraViewController) as! AirLocalCameraViewController
            
            self.presentViewController(airLocalCameraViewController, animated: true) { () -> Void in
                print("AirLocalCameraViewController")
            }
        }
        
        let airCameraButtonAction = UIAlertAction(title: "AirCamera", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("AirCamera")
            
            let airCameraViewController: AirCameraViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirCameraViewController) as! AirCameraViewController
            
            self.presentViewController(airCameraViewController, animated: true) { () -> Void in
                print("AirCameraViewController")
            }
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
            //FileManager.deleteSubFolder("airfolder/tmp")
        }
        
        actionSheet.addAction(localCameraButtonAction)
        actionSheet.addAction(airCameraButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
    
    @IBAction func unwindBackToShowCollectionController(unwindSegue: UIStoryboardSegue) {
        // todo:unwindSegue.sourceViewController.isKindOfClass()
        
        print(self.airShowPath)
        if let folder = self.airShowPath {
            let newShowPath = FileManager.getSubDirectoryPath(folder)
            //self.airShows.append(newShowPath)
            //let insertIndexpath = NSIndexPath(forItem: self.airShows.count - 1, inSection: 0)
            self.airShows.insert(newShowPath, atIndex: 0)
            let insertIndexpath = NSIndexPath(forItem: 0, inSection: 0)
            // todo:遷移元でmainスレッドにしている
            //dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.collectionView?.insertItemsAtIndexPaths([insertIndexpath])
            //})
            self.airShowPath = nil
        }
        
        /*
        self.airShows = FileManager.getFilePathsInSubDir(self.airShowFlolder)
        self.airShowCount = self.airShows.count
        self.collectionView?.reloadData()
        */
    }

}
