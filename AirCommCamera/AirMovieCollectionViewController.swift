//
//  AirMovieCollectionViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/12.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit


class AirMovieCollectionViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AirShowObserver {
    
    let identifierAirSoundViewController = "AirSoundViewController"
    let identifierAirMovieEditViewController = "AirMovieEditViewController"
    let reuseIdentifierMovieCell = "AirMovieCell"
    
    @IBOutlet weak var airMovieCollectionView: UICollectionView!
    @IBOutlet weak var progressView: UIProgressView!
    
    var airShowMan: AirShowManager?
    // todo:after?
    var airMovieFlolder: String?
    var airMovies: [AirMovie] = []
    var airMovieCount: Int = 0;
    var seletectPath: NSIndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirMovieCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifierMovieCell)

        // Do any additional setup after loading the view.
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
        
        self.progressView.progress = 0.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // 作成されたタイミングで随時追加
        let filePaths: [String]? = FileManager.getFilePathsInSubDir(self.airMovieFlolder) as? [String]
        if filePaths != nil {
            for filePath in filePaths! {
                let airMovie: AirMovie = AirMovie(path: filePath)
                self.airMovies.append(airMovie)
            }
            self.airMovieCount = self.airMovies.count
        }
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
        let thumbnail: UIImage? = self.airShowMan!.thumbnailOfVideo(airMovie.filePath)
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
    
    func progress(progress: Float, inConnectingMovies moviePath: String!) {
        // todo: add progress bar
        print("ConnectingMovie progress:\(progress)")
        
        if (progress == 100) {
            [self.performSegueWithIdentifier(self.identifierAirSoundViewController, sender: moviePath)]
        }
    }
    
    // MARK: Action
    
    @IBAction func nextAction(sender: AnyObject) {
        let moviePath = FileManager.getPathWithFileName("airmovie.mov", fromFolder: "airfolder/tmp/sound")
        self.airShowMan!.connectAirMovies(self.airMovies, movie: moviePath)
    }
    
    @IBAction func addAction(sender: AnyObject) {
        
    }

}
