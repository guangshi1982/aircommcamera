//
//  AirImageCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/07/27.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class AirImageCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, AirShowObserver {
    
    let identifierAirImageCell = "AirImageCell"
    let identifierAirShowCollectionViewController = "AirShowCollectionViewController"
    let identifierAirShowNavigationController = "AirShowNavigationController"
    let identifierAirLocalCameraViewController = "AirLocalCameraViewController"
    let identifierAirCameraViewController = "AirCameraViewController"
    let identifierAirProgressViewController = "AirProgressViewController"
    let numberOfColumns: CGFloat = 4
    
    var parentDir: String?
    var airImages: [AirImage] = []
    var airFileMan: AirFileManager?
    var airShowMan: AirShowManager?
    var airImageMan: AirImageManager?
    var progressOfProcess: Float = 0.0
    
    var pathType: Int = 0 // TBD 0:local 1:flashair 2:image data
    
    var airProgressViewController: AirProgressViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirImageCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // memo:不要(storyboardでIDを指定したから？)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: identifierAirImageCell)

        // Do any additional setup after loading the view.
        
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
        
        //self.airImageMan = AirImageManager.getInstance()
        
        print("self.parentDir:\(self.parentDir)")
        
        // todo:async
        if (self.pathType == 0) {
            let filePaths: [String]? = FileManager.getFilePathsInSubDir(self.parentDir) as? [String]
            if filePaths != nil {
                for filePath in filePaths! {
                    let airImage: AirImage = AirImage(path: filePath)
                    self.airImages.append(airImage)
                }
            }
        } else if (self.pathType == 1) {
            self.airFileMan = AirFileManager.getInstance()
            let airImages: [AirImage]? = self.airFileMan?.imagesAtDirectory(self.parentDir) as? [AirImage]
            if (airImages != nil) {
                for airImage in airImages! {
                    let fileData: NSData? = self.airFileMan?.getFileData(airImage.filePath)
                    let image: UIImage? = UIImage(data: fileData!)
                    airImage.image = image
                    self.airImages.append(airImage)
                    /*
                    let bounds = CGRect(origin: CGPointZero, size: airImage.image.size)
                    let faceInfos: [DetectInfo]? = airImageMan?.detectFace(airImage.image, inBounds: bounds) as? [DetectInfo]
                    
                    if (faceInfos != nil && faceInfos?.count > 0) {
                    print("face detected")
                    self.airImages.append(airImage)
                    }*/
                }
            }
        } else if (self.pathType == 2) {
            
        }
        
        print("self.airImages.count:\(self.airImages.count)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        print("prepareForSegue[AirImageCollectionViewController]")
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == self.identifierAirShowNavigationController {
            let airShowNavigationController = segue.destinationViewController as! UINavigationController
            let airImageSelectedViewController: AirImageSelectedViewController = airShowNavigationController.topViewController as! AirImageSelectedViewController
            airImageSelectedViewController.airImages = sender as! [AirImage]
            
            airImageSelectedViewController.airImages = self.airImages
        } else if segue.identifier == self.identifierAirShowCollectionViewController {
            let airShowCollectionViewController = segue.destinationViewController as! AirShowCollectionViewController
            airShowCollectionViewController.airShowPath = sender as? String
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airImages.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirImageCell, forIndexPath: indexPath) as! AirImageCell
        
        print("cellForItemAtIndexPath")
        
        // Configure the cell
        //let airFile: AirFile = self.airFiles[indexPath.row] as AirFile
        //let fileData: NSData? = self.airFileMan?.getFileData(airFile.filePath)
        //let image: UIImage? = UIImage(data: fileData!)
        let airImage: AirImage = self.airImages[indexPath.row] as AirImage
        cell.imageView?.image = airImage.image
    
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
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width: CGFloat = (CGRectGetWidth(self.view.frame) - CGFloat(2.0) * CGFloat(numberOfColumns - 1)) / numberOfColumns
        print("width:\(width)")
        
        return CGSizeMake(width, width)
    }
    
    // MARK: AirShowObserver
    
    func progress(progress: Float, inCreatingMovies movieFile: String!, inFolder movieFolder: String!) {
        print("CreatingMovie progress:\(progress)")
        
        /*
        self.progress(progress, ratioOf: 1.0 / 4)
        
        if (progress == 100) {
            var airMovies: [AirMovie] = []
            let filePaths: [String]? = FileManager.getFilePathsInSubDir(movieFolder) as? [String]
            if filePaths != nil {
                for filePath in filePaths! {
                    let airMovie: AirMovie = AirMovie(path: filePath)
                    airMovies.append(airMovie)
                }
            }
            self.airShowMan!.transformAirMovies(airMovies, movies: "airfolder/tmp/transform")
        }*/

        self.progress(progress, ratioOf: 1.0 / 2)
        
        if (progress == 100) {
            var airMovies: [AirMovie] = []
            let moviePath = FileManager.getPathWithFileName("airmovie.mov", fromFolder: "airfolder/tmp/sound")
            let filePaths: [String]? = FileManager.getFilePathsInSubDir(movieFolder) as? [String]
            if filePaths != nil {
                for filePath in filePaths! {
                    let airMovie: AirMovie = AirMovie(path: filePath)
                    airMovies.append(airMovie)
                }
            }
            self.airShowMan!.connectAirMovies(airMovies, movie: moviePath)
        }
    }
    
    func progress(progress: Float, inTransformingMovies movieFile: String!, inFolder movieFolder: String!) {
        print("TransformingMovie progress:\(progress)")
        
        self.progress(progress, ratioOf: 1.0 / 4)
        
        if (progress == 100) {
            var airMovies: [AirMovie] = []
            let moviePath = FileManager.getPathWithFileName("airmovie.mov", fromFolder: "airfolder/tmp/sound")
            let filePaths: [String]? = FileManager.getFilePathsInSubDir(movieFolder) as? [String]
            if filePaths != nil {
                for filePath in filePaths! {
                    let airMovie: AirMovie = AirMovie(path: filePath)
                    airMovies.append(airMovie)
                }
            }
            self.airShowMan!.connectAirMovies(airMovies, movie: moviePath)
        }
    }
    
    func progress(progress: Float, inConnectingMovies moviePath: String!) {
        print("ConnectingMovie progress:\(progress)")
        
        self.progress(progress, ratioOf: 1.0 / 4)
        
        if (progress == 100) {
            let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
            let airSound: AirSound = AirSound(path: soundPath)
            let airMovie: AirMovie = AirMovie(path: moviePath)
            let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: "airfolder/tmp/show")
            self.airShowMan!.createAirShowFromAirMovie(airMovie, withAirSound: airSound, show: showPath)
        }
    }
    
    func progress(progress: Float, inCreatingShow showPath: String!) {
        // todo:progress bar
        print("AddingSoundToMovie progress:\(progress)")
        
        self.progress(progress, ratioOf: 1.0 / 4)
        
        if (progress == 100) {
            // todo: rename tmp folder and save to show folder
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let dstPath = "airshow/" + dateFormatter.stringFromDate(now)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath("airfolder/tmp", toPath: dstPath)
            
            // unwind
            dispatch_async(dispatch_get_main_queue()) {
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    print("dismissAirProgressViewController")
                    // todo:progress画面が表示されるのが原因？で追加されたShowが表示されない。
                    // 実際見えないが、LocalCameraが表示されるな(viewWillAppearなど).unwindでshow一覧画面に戻るので、途中で自動的にImage一覧画面が消え、LocalCamera画面が表示されたかも。ただすぐLocalCamera画面も破棄されshow一覧が表示される(新規showはすでに追加されている)
                    self.performSegueWithIdentifier(self.identifierAirShowCollectionViewController, sender: dstPath)
                    }
                )
            }
        }
    }
    
    func progress(progress: Float, inProcessingShow showPath: String!) {
        
    }
    
    private func progress(progress: Float, ratioOf ratio: Float) {
        let progressOfAll = self.progressOfProcess + progress * ratio
        
        if (progress == 100) {
            self.progressOfProcess = progressOfAll
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.airProgressViewController?.updateProgress(CGFloat(progressOfAll))
        }
    }
    
    // MARK: Action
    
    @IBAction func autoCreate(sender: AnyObject) {
        FileManager.deleteSubFolder("airfolder/tmp")
        FileManager.createSubFolder("airfolder/tmp/image/before")// original images
        FileManager.createSubFolder("airfolder/tmp/image/after")// for effect
        FileManager.createSubFolder("airfolder/tmp/movie") // none effect(from images with ). And connected movie named [airmovie.xxx]
        FileManager.createSubFolder("airfolder/tmp/transform") // transition
        FileManager.createSubFolder("airfolder/tmp/sound") // connected movie from movies (no sound)
        FileManager.createSubFolder("airfolder/tmp/show")
        
        self.airProgressViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirProgressViewController) as! AirProgressViewController
        // todo:custom segue
        self.presentViewController(self.airProgressViewController!, animated: true) { () -> Void in
            print("AirProgressViewController")
            self.airShowMan!.createAirMoviesWithAirImages(self.airImages, movies: "airfolder/tmp/movie")
        }
    }

    @IBAction func cancelAction(sender: AnyObject) {
        if (self.pathType == 0) {
            self.performSegueWithIdentifier(self.identifierAirLocalCameraViewController, sender: nil)
        } else if (self.pathType == 1) {
            self.performSegueWithIdentifier(self.identifierAirCameraViewController, sender: nil)
        } else if (self.pathType == 2) {
            self.performSegueWithIdentifier(self.identifierAirShowCollectionViewController, sender: nil)
        }
    }
    
    @IBAction func doneAction(sender: AnyObject) {
        // no segue id (it's storyboard id)
        //self.performSegueWithIdentifier(self.identifierAirShowNavigationController, sender: self.airImages)
        
        let airShowNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirShowNavigationController) as! UINavigationController
        let airImageSelectedViewController: AirImageSelectedViewController = airShowNavigationController.topViewController as! AirImageSelectedViewController
        airImageSelectedViewController.airImages = self.airImages
        
        self.presentViewController(airShowNavigationController, animated: true) { () -> Void in
            print("AirShowNavigationController")
        }
    }
}
