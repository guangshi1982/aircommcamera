//
//  AirImageEditViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/14.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class FilterHelper: NSObject {
    
    class func filterNamesFor_iOS9(category: String?) -> [String]! {
        
        return FilterHelper.filterNamesFor_iOS9(category, exceptCategories: nil)
    }
    
    class func filterNamesFor_iOS9(category: String?, exceptCategories: [String]?) -> [String]! {
        
        var filterNames:[String] = []
        let all = CIFilter.filterNamesInCategory(category)
        
        for aFilterName in all {
            
            let attributes = CIFilter(name: aFilterName)!.attributes
            if exceptCategories?.count > 0 {
                var needExcept = false
                let categories = attributes[kCIAttributeFilterCategories] as! [String]
                for aCategory in categories {
                    if (exceptCategories?.contains(aCategory) == true) {
                        needExcept = true
                        break
                    }
                }
                if needExcept {
                    continue
                }
            }
            
            let availability = attributes[kCIAttributeFilterAvailable_iOS]
            //            print("filtername:\(aFilterName), availability:\(availability)")
            
            if availability != nil &&
                availability as! String == "9" {
                    filterNames.append(aFilterName)
            }
        }
        return filterNames
    }
}

class AirImageEditViewController: UIViewController {
    
    let identifierAirImageCell = "AirImageCell"
    let numberOfColumns: CGFloat = 10
    let filterImageSize: Int = 48
    
    @IBOutlet weak var editImageView: UIImageView?
    @IBOutlet weak var imageFilterCollectionView: UICollectionView?
    
    var imageSelectedViewController: AirImageSelectedViewController?
    var airImageMan: AirImageManager?
    var editImage: UIImage?
    var filterImage: UIImage?
    var airFilterImages: [AirImage] = []
    var airImageFilterCategories: [String] = []
    var airImageFilters: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirImageEditViewController viewDidLoad")

        // Do any additional setup after loading the view.
        // todo: [BSXPCMessage received error for message: Connection interrupted]発生。
        // 実際影響がなさそうだが、調査する
        self.airImageMan = AirImageManager.getInstance()
        
        self.airImageFilterCategories = self.airImageMan?.imageFilterCategories() as! [String]
        print("category count:\(self.airImageFilterCategories.count)")
        
        /*
        // memo:NG. 全てのカテゴリに入る(AND)フィルターになるので、0になる。
        //self.airImageFilters = self.airImageMan?.imageFilterNamesInCategories(self.airImageFilterCategories) as! [String]
        
        // memo:一つのフィルターが複数のカテゴリに属する可能性があるので、フィルターが重複するかも。必要であれば排除
        for category in self.airImageFilterCategories {
            print("category:\(category)")
            let filters: [String]? = self.airImageMan?.imageFilterNamesInCategory(category) as? [String]
            if filters != nil {
                for filter in filters! {
                    print("filter:\(filter)")
                    self.airImageFilters.append(filter)
                }
            }
        }*/
        
        // test
        let exceptCategories = [
            kCICategoryTransition,
            kCICategoryGenerator,
            kCICategoryReduction,
        ]
        // memo:kCICategoryBuiltIn is for all filters in iOS?
        self.airImageFilters = FilterHelper.filterNamesFor_iOS9(kCICategoryBuiltIn, exceptCategories: exceptCategories)
        //self.airImageFilters.insert("Original", atIndex: 0)
        print("filter count:\(self.airImageFilters.count)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.editImageView?.image = self.editImage
        let filterImageRect = CGRect(x: 0, y: 0, width: filterImageSize, height: filterImageSize)
        self.filterImage = self.airImageMan?.resizeImageToFill(self.editImage, bounds: filterImageRect)
        
        for filter in self.airImageFilters {
            // todo: get attributes of filter (contains e.g. fileter display name. And parameters setting for it)
            let filterImage: UIImage? = self.airImageMan?.imageFilteredWithName(filter, image: self.filterImage)
            if filterImage != nil {
                let airImage = AirImage(image: filterImage)
                self.airFilterImages.append(airImage)
            }
        }
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
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.airFilterImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(identifierAirImageCell, forIndexPath: indexPath) as! AirImageCell
        let airImage: AirImage? = self.airFilterImages[indexPath.row]
        if airImage != nil {
            cell.imageView?.image = airImage?.image
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
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let width: CGFloat = (CGRectGetWidth(self.view.frame) - CGFloat(2.0) * CGFloat(numberOfColumns - 1)) / numberOfColumns
        
        // memo:cellのサイズ。中のimageはautolayoutで変更(設定しないとdefaultのcellサイズ。ハマった。。。)
        return CGSizeMake(width, width)
    }
    
    
    private func drawRectangle(rect: CGRect, part: Int) {
#if false
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        var rectPath = UIBezierPath(rect: rect)
        //rectPath.moveToPoint(rect.origin)
        rectPath.lineWidth = 1
        if (part == 0) {
            UIColor.redColor().setStroke()
        } else if (part == 1) {
            UIColor.greenColor().setStroke()
        } else if (part == 2) {
            UIColor.blueColor().setStroke()
        }
        rectPath.stroke()
        
        self.view.layer.contents = UIGraphicsGetImageFromCurrentImageContext().CGImage
        UIGraphicsEndImageContext()
            
#else
        
        // 画像の顔の周りを線で囲うUIViewを生成.
        let faceOutline = UIView(frame: rect)
        var borderColor = UIColor.redColor().CGColor
    
        if (part == 0) {
            borderColor = UIColor.redColor().CGColor
        } else if (part == 1) {
            borderColor = UIColor.greenColor().CGColor
        } else if (part == 2) {
            borderColor = UIColor.blueColor().CGColor
        }
        faceOutline.layer.borderColor = borderColor
        faceOutline.layer.borderWidth = 1
        self.editImageView!.addSubview(faceOutline)
#endif
    }

    // MARK: Action
    @IBAction func detectFace(sender: AnyObject) {
        let detectItem: UIBarButtonItem = sender as! UIBarButtonItem
        
        if (detectItem.tag == 1) {
            //var airImageMan: AirImageManager? = AirImageManager.getInstance()
            let faceInfos: [DetectInfo]? = airImageMan?.detectFace(self.editImageView?.image, inBounds: self.editImageView!.bounds) as? [DetectInfo]
            
            if (faceInfos != nil && faceInfos?.count > 0) {
                for faceInfo: DetectInfo in faceInfos! {
                    var rect: CGRect = faceInfo.face.bounds
                    self.drawRectangle(rect, part: 0)
                    
                    if (faceInfo.face.hasMouth) {
                        rect = CGRectMake(faceInfo.face.mouthPosition.x, faceInfo.face.mouthPosition.y, faceInfo.face.bounds.size.width / 5, faceInfo.face.bounds.size.height / 5)
                        self.drawRectangle(rect, part: 1)
                    }
                    
                    if (faceInfo.face.hasLeftEye) {
                        rect = CGRectMake(faceInfo.face.leftEyePosition.x, faceInfo.face.leftEyePosition.y, faceInfo.face.bounds.size.width / 10, faceInfo.face.bounds.size.height / 10)
                        self.drawRectangle(rect, part: 2)
                    }
                    
                    if (faceInfo.face.hasRightEye) {
                        rect = CGRectMake(faceInfo.face.rightEyePosition.x, faceInfo.face.rightEyePosition.y, faceInfo.face.bounds.size.width / 10, faceInfo.face.bounds.size.height / 10)
                        self.drawRectangle(rect, part: 2)
                    }
                }
            }
        }
        
    }
    
    @IBAction func filterImageSaveAction(sender: AnyObject) {
        // todo:save image
        
        if self.imageSelectedViewController != nil {
            self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func filterImageCancelAction(sender: AnyObject) {
        if self.imageSelectedViewController != nil {
            self.imageSelectedViewController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
