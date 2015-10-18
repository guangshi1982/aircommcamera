//
//  AirShowCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit
import QBImagePickerController

class AirShowCollectionViewController: UICollectionViewController, QBImagePickerControllerDelegate, AirShowObserver {
    
    let identifierAirShowCell = "AirShowCell"
    let identifierAirShowEditViewController = "AirShowEditViewController"
    let identifierAirPreviewController = "AirPreviewController"
    let identifierAirLocalCameraViewController = "AirLocalCameraViewController"
    let identifierAirCameraViewController = "AirCameraViewController"
    let identifierAirFolderNavigationController = "AirFolderNavigationController"
    let identifierAirFolderCollectionViewController = "AirFolderCollectionViewController"
    let identifierAirActionNavigationController = "AirActionNavigationController"
    let identifierAirShowNavigationController = "AirShowNavigationController"
    
    var airShowMan: AirShowManager?
    var airFileMan: AirFileManager?
    var airShowPath: String?
    var airShowFlolder: String = "airshow"
    //var airShowFlolder: String = "airmovie" //test
    // todo: [AirShow]
    var airShows: [AnyObject] = []
    var airShowCount: Int = 0;
    var seletectPath: NSIndexPath?

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
        //self.airShowPath = FileManager.getSubDirectoryPath("airshow")
        //self.airShowPath = FileManager.getSubDirectoryPath("airmovie") // test
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // todo:update by event in which show created
        self.airShows = FileManager.getFilePathsInSubDir(self.airShowFlolder)
        self.airShowCount = self.airShows.count
        //self.airShowCount = Int(FileManager.getFileCountInSubDir(self.airShowFlolder))
        print("airShowCount:\(self.airShowCount)")
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
            let airshowPlayerController = segue.destinationViewController as! AirShowEditViewController
            airshowPlayerController.videoPath = cell.airShowPath
            airshowPlayerController.updateVideo()
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
        return self.airShowCount
        //return 0 // test
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirShowCell, forIndexPath: indexPath) as! AirShowCell
        
        // Configure the cell
        // todo:nil check
        let showFolder = self.airShows[indexPath.row] as! String
        let showPath = showFolder + "/" + "show/airshow.mov"
        let thumbnail: UIImage? = self.airShowMan!.thumbnailOfVideo(showPath)
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
    
    // MARK: AirShowObserver
    
    func progress(progress: Float, inCreatingMovie moviePath: String!) {
        
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
            
            // memo:一旦前のviewをdismissする必要がある
            let airShowNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirShowNavigationController) as! UINavigationController
            let airImageSelectedViewController: AirImageSelectedViewController = airShowNavigationController.topViewController as! AirImageSelectedViewController
            airImageSelectedViewController.airImages = airImages
            
            self.presentViewController(airShowNavigationController, animated: true) { () -> Void in
                print("AirShowNavigationController")
            }
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
        airShowMan.createAirMovieWithAirImage(airImage, movie: moviePath)
        
    }
    
    @IBAction func createAirShow(sender: AnyObject) {
        
        // todo: create tmp folder[airfolder(TBD)] for creating image/movie/show
        //       rename tmp folder to new folder when success for creating
        //       delete when canceled or failed for creating
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
        

        // added in iOS8
        let actionSheet = UIAlertController(title: "Create slide show", message: "Select images from below", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cameraButtonAction = UIAlertAction(title: "Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Camera")
            
            let airLocalCameraViewController: AirLocalCameraViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirLocalCameraViewController) as! AirLocalCameraViewController
            
            self.presentViewController(airLocalCameraViewController, animated: true) { () -> Void in
                print("AirLocalCameraViewController")
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
        
        let snsButtonAction = UIAlertAction(title: "SNS", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("SNS")
        }
        
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
        
        actionSheet.addAction(cameraButtonAction)
        actionSheet.addAction(photosButtonAction)
        actionSheet.addAction(snsButtonAction)
        actionSheet.addAction(flashairButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }

    }
    
    @IBAction func shareAirShow(sender: AnyObject) {
        
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
        //let showPath = "" // from sourceViewController?(add property)
        //self.airShows.append(showPath)
        //let indexPath = NSIndexPath(forItem: self.airShows.count, inSection: 0)
        //self.collectionView?.insertItemsAtIndexPaths([indexPath])
        
        self.airShows = FileManager.getFilePathsInSubDir(self.airShowFlolder)
        self.airShowCount = self.airShows.count
        self.collectionView?.reloadData()
        
    }

}
