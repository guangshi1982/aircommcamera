//
//  AirImageSelectedViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/12.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit


class AirImageSelectedViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AirShowObserver {
    
    let QUEUE_SERIAL_CREATE_MOVIE = "com.threees.aircomm.aircam.create-movie"
    let identifierAirMovieCollectionViewController = "AirMovieCollectionViewController"
    let identifierAirImageEditViewController = "AirImageEditViewController"
    let identifierAirProgressViewController = "AirProgressViewController"
    let identifierAirImageCell = "AirImageCell"
    let numberOfColumnsForMain: CGFloat = 1
    let numberOfColumnsForSub: CGFloat = 10
    
    @IBOutlet weak var mainImageCollectionView: UICollectionView!
    @IBOutlet weak var subImageCollectionView: UICollectionView!
    
    var airProgressViewController: AirProgressViewController!
    
    var airShowMan: AirShowManager?
    var airImages: [AirImage] = []
    // todo:movieのfolderからmovieの配列を作成
    var airMovies: [AirMovie] = []
    
    // todo: create queue in AirShowManager?
    var movieQueue: dispatch_queue_t?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirImageSelectedCollectionViewController viewDidLoad")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        // memo:不要(storyboardでIDを指定したから？)
        //self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: identifierAirImageCell)

        // Do any additional setup after loading the view.
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
        self.movieQueue = dispatch_queue_create(QUEUE_SERIAL_CREATE_MOVIE, DISPATCH_QUEUE_SERIAL)
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
        if segue.identifier == self.identifierAirMovieCollectionViewController {
            print("prepareForSegue[create movies]")
            let airMovieCollectionViewController = segue.destinationViewController as! AirMovieCollectionViewController
            airMovieCollectionViewController.airMovieFlolder = sender as? String
            // memo: need to set before create movies
            self.airShowMan?.observer = airMovieCollectionViewController
            
            // todo: create in movie controller? (set air images to movie controller)
            dispatch_async(self.movieQueue!, { () -> Void in
                self.airShowMan!.createAirMoviesWithAirImages(self.airImages, movies: airMovieCollectionViewController.airMovieFlolder)
            })
            
            /*
            var imageCount = self.airImages.count
            for var i = 0; i < imageCount; i++ {
                var airImage: AirImage = self.airImages[i] as AirImage
                dispatch_async(self.movieQueue!, { () -> Void in
                    // create movie
                })
            }*/
            
        } else if segue.identifier == self.identifierAirImageEditViewController {
            let airImageEditViewController = segue.destinationViewController as! AirImageEditViewController
            let cell = sender as! AirImageCell
            // memo: editImageViewを設定するとき、viewDidLoadがまだ実行されていないので、実際UIImageViewは生成されていない。
            // 一旦UIImageに保存してからUIImageViewへ設定
            airImageEditViewController.editImage = cell.imageView?.image
            airImageEditViewController.imageSelectedViewController = self
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airImages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("tag:\(collectionView.tag)")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirImageCell, forIndexPath: indexPath) as! AirImageCell
    
        // Configure the cell
        // todo:78x78のImageにしてautolayoutで拡大しているので、表示画質が悪い？
        let airImage: AirImage = self.airImages[indexPath.row] as AirImage
        let image: UIImage = airImage.image
        cell.imageView?.image = image
    
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
        var numberOfColumns: CGFloat = numberOfColumnsForMain
        if collectionView.tag == 1 {
            numberOfColumns = numberOfColumnsForMain
        } else if collectionView.tag == 2 {
            numberOfColumns = numberOfColumnsForSub
        }
        
        let width: CGFloat = (CGRectGetWidth(self.view.frame) - CGFloat(2.0) * CGFloat(numberOfColumns - 1)) / numberOfColumns
        
        // memo:cellのサイズ。中のimageはautolayoutで変更(設定しないとdefaultのcellサイズ。ハマった。。。)
        return CGSizeMake(width, width)
    }
    
    // MARK: AirShowObserver
    /*
    func progress(progress: Float, inCreatingMovies movieFolder: String!) {
        // todo: add progress bar
        print("CreatingMovie progress:\(progress)")
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.airProgressViewController?.updateProgress(CGFloat(progress))
        }
        //self.airProgressViewController?.updateProgress(CGFloat(progress))
        
        if (progress == 100) {
            [self.performSegueWithIdentifier(self.identifierAirMovieCollectionViewController, sender: movieFolder)]
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                print("dismissAirProgressViewController")
                }
            )
        }
    }*/

    // MARK: Action
    
    @IBAction func nextAction(sender: AnyObject) {
        /*
        self.airProgressViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirProgressViewController) as! AirProgressViewController
        // todo:custom segue
        self.presentViewController(self.airProgressViewController!, animated: true) { () -> Void in
            print("AirProgressViewController")
            self.airShowMan!.createAirMoviesWithAirImages(self.airImages, movies: "airfolder/tmp/movie")
        }*/
        
        // todo: in storyborad?
        [self.performSegueWithIdentifier(self.identifierAirMovieCollectionViewController, sender: "airfolder/tmp/movie")]
    }
    
    @IBAction func addAction(sender: AnyObject) {
        
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
    }
    
    @IBAction func editAction(sender: AnyObject) {
        
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismiss AirImageSelectedCollectionViewController")
        })
    }
}
