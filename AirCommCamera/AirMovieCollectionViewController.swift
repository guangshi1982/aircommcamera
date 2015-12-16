//
//  AirMovieCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/12.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit


class AirMovieCollectionViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AirShowObserver {
    
    let QUEUE_SERIAL_CONNECT_MOVIE = "com.threees.aircomm.aircam.connect-movie"
    let identifierAirSoundViewController = "AirSoundViewController"
    let identifierAirMovieEditViewController = "AirMovieEditViewController"
    let reuseIdentifierMovieCell = "AirMovieCell"
    
    @IBOutlet weak var nextBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var airMovieCollectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var airShowMan: AirShowManager?
    // todo:after?
    var airMovieFlolder: String?
    var tmpAirMovies: [AirMovie] = []
    var airMovies: [AirMovie] = []
    var seletectPath: NSIndexPath?
    var progressOfProcess: Float = 0.0
    
    // todo: create queue in AirShowManager?
    var movieQueue: dispatch_queue_t?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirMovieCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifierMovieCell)

        // Do any additional setup after loading the view.
        self.airShowMan = AirShowManager.getInstance()
        // memo: set in parent view controller(selected view controller)
        //self.airShowMan!.observer = self
        
        self.movieQueue = dispatch_queue_create(QUEUE_SERIAL_CONNECT_MOVIE, DISPATCH_QUEUE_SERIAL)
        
        self.nextBarButtonItem.enabled = false
        self.progressView.progress = 0.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // 作成されたタイミングで随時追加
        /*
        let filePaths: [String]? = FileManager.getFilePathsInSubDir(self.airMovieFlolder) as? [String]
        if filePaths != nil {
            for filePath in filePaths! {
                let airMovie: AirMovie = AirMovie(path: filePath)
                self.airMovies.append(airMovie)
            }
        }*/
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
        print("prepareForSegue[connect movies]")
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == self.identifierAirSoundViewController {
            let airSoundViewController = segue.destinationViewController as! AirSoundViewController
            airSoundViewController.videoPath = sender as? String
            self.airShowMan?.observer = airSoundViewController
            
            dispatch_async(self.movieQueue!, { () -> Void in
                self.airShowMan!.connectAirMovies(self.airMovies, movie: airSoundViewController.videoPath)
            })
        } else if segue.identifier == self.identifierAirMovieEditViewController {
            let airMovieEditViewController = segue.destinationViewController as! AirMovieEditViewController
            let cell = sender as! AirMovieCell
            airMovieEditViewController.videoPath = cell.moviePath
            airMovieEditViewController.updateVideo()
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("numberOfItemsInSection")
        return self.airMovies.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("cellForItemAtIndexPath:\(indexPath.row)")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifierMovieCell, forIndexPath: indexPath) as! AirMovieCell
    
        // Configure the cell
        let airMovie = self.airMovies[indexPath.row]
        let thumbnail: UIImage? = self.airShowMan!.thumbnailOfVideo(airMovie.filePath, withSize: (cell.thumbnailImageView?.bounds.size)!)
        if (thumbnail != nil) {
            cell.thumbnailImageView?.image = thumbnail
            cell.moviePath = airMovie.filePath
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
    
    func progress(progress: Float, inCreatingMovies movieFile: String!, inFolder movieFolder: String!) {
        // todo: add progress bar
        print("CreatingMovie progress:\(progress)")
        
        let airMovie: AirMovie = AirMovie(path: movieFile)
        self.airMovies.append(airMovie)
        let indexPath = NSIndexPath(forItem: self.airMovies.count - 1, inSection: 0)
        self.progress(progress, ratioOf: 1)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.airMovieCollectionView.insertItemsAtIndexPaths([indexPath])
            // todo:scroll to new movie
            
            if (progress == 100) {
                //self.progressView.progress = 0.0
                self.progressView.hidden = true
                self.nextBarButtonItem.enabled = true
                // todo:scroll to first?
                
                self.airShowMan?.observer = nil
            }
        }
        
        /*
        let airMovie: AirMovie = AirMovie(path: movieFile)
        self.tmpAirMovies.append(airMovie)
        self.progress(progress, ratioOf: 1.0 / 2)
        
        if (progress == 100) {
            self.airShowMan!.transformAirMovies(self.tmpAirMovies, movies: "airfolder/tmp/transform")
        }*/
    }
    
    func progress(progress: Float, inTransformingMovies movieFile: String!, inFolder movieFolder: String!) {
        print("TransformingMovie progress:\(progress)")
        
        let airMovie: AirMovie = AirMovie(path: movieFile)
        self.airMovies.append(airMovie)
        let indexPath = NSIndexPath(forItem: self.airMovies.count - 1, inSection: 0)
        self.progress(progress, ratioOf: 1.0 / 2)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.airMovieCollectionView.insertItemsAtIndexPaths([indexPath])
            // todo:scroll to new movie
            
            if (progress == 100) {
                //self.progressView.progress = 0.0
                self.progressView.hidden = true
                self.nextBarButtonItem.enabled = true
                // todo:scroll to first?
                
                self.airShowMan?.observer = nil
            }
        }
    }
    
    /*
    func progress(progress: Float, inConnectingMovies moviePath: String!) {
        // todo: add progress bar
        print("ConnectingMovie progress:\(progress)")
        
        if (progress == 100) {
            [self.performSegueWithIdentifier(self.identifierAirSoundViewController, sender: moviePath)]
        }
    }*/
    
    private func progress(progress: Float, ratioOf ratio: Float) {
        let progressOfAll = self.progressOfProcess + progress * ratio
        
        if (progress == 100) {
            self.progressOfProcess = progressOfAll
        }
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.progressView.progress = progressOfAll / 100.0
        }
    }
    
    // MARK: Action
    
    @IBAction func nextAction(sender: AnyObject) {
        let moviePath = FileManager.getPathWithFileName("airmovie.mov", fromFolder: "airfolder/tmp/sound")
        /*self.airShowMan!.connectAirMovies(self.airMovies, movie: moviePath)*/
        self.performSegueWithIdentifier(self.identifierAirSoundViewController, sender: moviePath)
    }
    
    @IBAction func addAction(sender: AnyObject) {
        
    }

}
