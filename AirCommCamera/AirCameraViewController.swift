//
//  AirCameraViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/10/13.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

protocol AirCameraViewControllerDelegate {
    func airCameraViewController(airCameraViewController: AirCameraViewController, didFinishAddingAirshowToPath folderPath: String)
}

class AirCameraViewController: UIViewController, AirSensorObserver, AirShowObserver, AirFileManagerDelegate {
    
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirImageNavigationController = "AirImageNavigationController"
    let identifierAirProgressViewController = "AirProgressViewController"
    let identifierAirShowCollectionViewController = "AirShowCollectionViewController"
    
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.aircomm.image-save"
    
    let MAX_FRAME_COUNT_FOR_SAVE: UInt = 3 // 保存判断用最大frame数
    let MAX_FRAME_COUNT_FOR_MOVIE: UInt = 2
    
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var saveView: UIView! = nil
    @IBOutlet weak var saveImageView: UIImageView! = nil
    
    var delegate: AirCameraViewControllerDelegate?
    
    var airShowMan: AirShowManager? = nil
    var airFileMan: AirFileManager? = nil // @
    var sensorMan: AirSensorManager? = nil
    var cameraCtrl: AirCameraController? = nil
    var captureSetup: Bool = false // カメラ設定フラグ
    var captureStart: Bool = false //
    var imageCapture: Bool = false // 画像キャプチャフラグ
    var syncCamera: Bool = false // 外付カメラとの同期フラグ(画像キャプチャ開始フラグ)
    var autoCapture: Bool = false // 自動キャプチャフラグ
    var syncInterval: NSTimeInterval = 5 // キャプチャ間隔(UI設定可能)
    var sensorStart: Bool = false // センサー起動フラグ
    var initLocation: Bool = false // ?
    var dispImage: Bool = true // 自動キャプチャ時画像保存フラグ(接近フラグ)
    var dispSensorGraph: Bool = false // デバッグ用。センサーフラグ表示フラグ
    var creatingShow: Bool = false // 現在show作成中フラグ todo:処理が遅い場合、Folderの調整
    
    var latestImageIndex: Int32 = 0
    
    var imageSaveQueue: dispatch_queue_t?
    var syncCameraTimer: NSTimer?
    
    var imageSavePath: String? = "aircamera/tmp/image/before"
    // todo:create movie when capture image
    var movieMakePath: String? = "aircamera/tmp/movie"
    var imageSaveCount: UInt = 0 // 保存済み画像数
    var showCreateCount: UInt = 0 // 作成済みスライド数
    var currentShowCount: UInt = 0 // 現在作成中スライド番号
    var imageFrameCount: UInt = 0 // 保存対象frame数
    
    var currentSensorInfo: AirSensorInfo?
    
    var airProgressViewController: AirProgressViewController!
    var progressOfProcess: Float = 0.0
    
    override func viewDidLoad() {
        Log.debug("CaputureView viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.debug("CaputureView viewWillAppear")
        super.viewWillAppear(animated)
        
        // todo:test
        //self.startSensor()
        
        // アプリ内画面切替時（例えば、設定画面から戻った場合）。アプリバック->再開では呼ばれない
        self.startCapture()
    }
    
    override func viewDidAppear(animated: Bool) {
        Log.debug("CaputureView viewDidAppear")
        super.viewDidAppear(animated)
        
        // アプリ内画面切替時（例えば、設定画面から戻った場合）。アプリ再開では呼ばれない
        
        // キャプチャ再開.一瞬キャプチャが止まるように見えるので、viewWillAppearで開始。
        // self.cameraCap?.startCapture()
        // self.stopCapture()
    }
    
    override func viewWillDisappear(animated: Bool) {
        Log.debug("CaputureView viewWillDisappear")
        super.viewWillDisappear(animated)
        
        // アプリ内画面切替時（例えば、設定画面に切替えた場合）。アプリがバックグランドへ移動時呼ばれない
    }
    
    override func viewDidDisappear(animated: Bool) {
        Log.debug("CaputureView viewDidDisappear")
        super.viewDidDisappear(animated)
        
        // アプリ内画面切替時（例えば、設定画面に切替えた場合）。アプリがバックグランドへ移動時呼ばれない
        
        // キャプチャ停止（画像処理停止）。一瞬キャプチャが止まるように見えるので、完全非表示後stop
        //self.cameraCap?.stopCapture()
        self.stopCapture()
        
        self.stopSensor()
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
    
    private func setup() {
        self.imageSaveQueue = dispatch_queue_create(QUEUE_SERIAL_IMAGE_SAVE, DISPATCH_QUEUE_SERIAL)
        FileManager.deleteSubFolder("aircamera/tmp/")
        
        self.airFileMan = AirFileManager.getInstance()
        self.airFileMan!.delegate = self;
        
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
        
        self.currentSensorInfo = AirSensorInfo()
        self.cameraCtrl = AirCameraController()
        self.setupCamera()
        self.setupSensor()
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            self.captureSetup = true
        }
    }
    
    private func setupSensor() {
        self.sensorMan = AirSensorManager.getInstance()
        self.sensorMan?.observer = self
        self.sensorMan?.addSensorType(AirSensorTypeProximity)
        /*self.sensorMan?.addSensorType(AirSensorTypeLocation)
        self.sensorMan?.addSensorType(AirSensorTypeHeading)
        self.sensorMan?.addSensorType(AirSensorTypeAcceleration)
        self.sensorMan?.addSensorType(AirSensorTypeGyro)
        self.sensorMan?.addSensorType(AirSensorTypeAttitude)*/
    }
    
    private func setupTmpFolder(folderNum: UInt) {
        //if (folderNum == 0) {
        //    FileManager.deleteSubFolder("aircamera/tmp/")
        //}
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/image/before")// original images
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/image/after")// for effect
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/movie") // none effect(from images with ). And connected movie named [airmovie.xxx]
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/transform") // transition
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/sound") // connected movie from movies (no sound)
        FileManager.createSubFolder("aircamera/tmp/\(folderNum)/show")
    }
    
    private func requestImage() {
        self.airFileMan?.requestLatestImage()
    }
    
    private func requestImageStartAt(index: Int32) {
        self.airFileMan?.requestLatestImageStartAt(index)
    }
    
    private func saveCapturedImage(image: UIImage?) {
        if (image != nil) {
            // memo:PNGの場合、orientationの情報が消える？ので。
            let data = UIImageJPEGRepresentation(image!, 1)
            //let data = UIImagePNGRepresentation(info.image!)// not dImage
            if (data == nil) {
                print("data is nil")
            }
            //let now = NSDate()
            // @memo double->string
            //let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
            let imageNameExt = String(format:"image_%d.png", self.imageSaveCount)
            // todo:save to sub folder of airimage
            FileManager.saveData(data, toFile: imageNameExt, inFolder: "aircamera/tmp/\(self.currentShowCount)/image/before")
        }
    }
    
    private func createMovie(image: AirImage?) {
        // todo:Folder作成
        //let moviePath = FileManager.getPathWithFileName(String(format: "%d.mov", self.imageSaveCount), fromFolder: "aircamera/tmp/movie")
        //self.airShowMan?.createAirMovieWithAirImage(image, movie: moviePath)
        //self.airShowMan?.createAirMovieWithAirImage(image, movie: String(format: "%d.mov", self.imageSaveCount), inFolder: "aircamera/tmp/\(self.currentShowCount)/movie")
        
        self.airShowMan?.createAirMovieWithAirImage(image, movie: String(format: "%d.mov", self.imageSaveCount), inFolder: "aircamera/tmp/\(self.currentShowCount)/movie")
    }
    
    private func createShow(showNum: UInt) {
        //let dstPath = String(format: "aircamera/%d", self.currentShowCount + 1)
        //FileManager.createSubFolder(dstPath)
        //FileManager.copyFromPath("aircamera/tmp", toPath: dstPath)
        
        var airMovies: [AirMovie] = []
        let filePaths: [String]? = FileManager.getFilePathsInSubDir("aircamera/tmp/\(showNum)/movie") as? [String]
        if filePaths != nil {
            for filePath in filePaths! {
                let airMovie: AirMovie = AirMovie(path: filePath)
                airMovies.append(airMovie)
            }
        }
        
        // todo:とりあえずsoundなし
        let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: "aircamera/tmp/\(showNum)/show")
        self.airShowMan!.connectAirMovies(airMovies, movie: showPath)
        
        /*
        let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
        let airSound: AirSound = AirSound(path: soundPath)
        let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: dstPath + "/show")
        self.airShowMan!.createAirShowFromAirMovies(airMovies, withAirSound: airSound, toShow: showPath)*/
        
        /*
        self.airProgressViewController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirProgressViewController) as! AirProgressViewController
        // todo:custom segue
        self.presentViewController(self.airProgressViewController!, animated: true) { () -> Void in
            print("AirProgressViewController")
            self.airShowMan!.createAirShowFromAirMovies(airMovies, withAirSound: airSound, toShow: showPath)
        }*/
    }
    
    private func imageOrientationFromCaptureOrientation(capOri: CameraOrientaion) -> UIImageOrientation {
        var imgOri = UIImageOrientation.Right
        
        switch (capOri) {
        case CameraOrientaion.Landscape:
            imgOri = UIImageOrientation.Right
            break
        case CameraOrientaion.Portrait:
            imgOri = UIImageOrientation.Up
            break
        }
        
        return imgOri
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
    
    
    // memo:NSTimerのSelectorの場合、privateにすると落ちる（見つからない?）
    func captureImage(timer: NSTimer) {
        self.autoCapture = true
        self.imageCapture = true
        self.requestImageStartAt(self.latestImageIndex)
    }
    
    func startCapture() {
        if (self.captureStart == false) {
            self.captureStart = true
        }
    }
    
    func stopCapture() {
        if (self.captureStart) {
            self.captureStart = false
        }
    }
    
    func startSensor() {
        if (self.sensorStart == false) {
            // todo:別スレッドにする->動作しないようだな->通知をまとめる
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.sensorMan?.start()
            //})
            self.sensorStart = true
        }
    }
    
    func stopSensor() {
        if (self.sensorStart == true) {
            self.sensorMan?.stop()
            //self.sensorLocationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorStart = false
        }
    }
    
    // MARK: - AirFileManagerDelegate protocol
    
    func airFileManager(manager: AirFileManager!, requestedLatestImage image: AirImage!) {
        // todo:display dummy image
        if image == nil || image.image == nil {
            return
        }
        let imageCaptured: UIImage = image.image
        if (self.imageCapture) {
            self.imageCapture = false
            // @memo:非同期なので、最大画像数まで制限しないと、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
            // 設定間隔内で処理が完了するはずなので、非同期にしてみる
            dispatch_async(self.imageSaveQueue!, { () -> Void in
                //dispatch_sync(self.imageSaveQueue!, { () -> Void in
                var canCapture: Bool = true
                if (self.autoCapture) {
                    //canCapture = (self.cameraCtrl?.canCaptureCurrentImage(self.currentSensorInfo!))!
                    canCapture = true
                }
                print("canCapture:\(canCapture)")
                if (canCapture) {
                    var canSave: Bool = true
                    if (self.autoCapture) {
                        canSave = (self.cameraCtrl?.canSaveCurrentImage(imageCaptured))!
                    }
                    if (canSave) {
                        //self.saveCapturedImage(info.image)
                        //imageCaptured = self.imageFromSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
                        self.saveCapturedImage(imageCaptured)
                        self.createMovie(image)
                        self.imageSaveCount++
                        if (self.imageSaveCount == self.MAX_FRAME_COUNT_FOR_MOVIE) {
                            self.currentShowCount++
                            self.imageSaveCount = 0
                            self.setupTmpFolder(self.currentShowCount)
                        }
                        
                        if (self.dispImage) {
                            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                self.saveImageView.image = imageCaptured
                            }
                        }
                    }
                    
                    /*
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    var animationImageView = UIImageView(frame: self.captureImageView.frame)
                    self.view.addSubview(animationImageView)
                    UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    
                    }, completion: { (Bool) -> Void in
                    
                    })
                    })*/
                }
            })
        }
        
        if (self.dispImage) {
            // @memo: queue in UI thread
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.capturedImageView.image = imageCaptured
            }
        }
    }
    
    // MARK: - AirSensorObserver protocol
    
    func capture(info: AirSensorInfo!) {
        
    }
    
    func displayCameraView(flag: Bool, info: AirSensorInfo!) {
        self.dispImage = !flag
    }
    
    func sensorInfo(info: AirSensorInfo!, ofType type: AirSensorType) {
        self.currentSensorInfo = info
    }
    
    // MARK: AirShowObserver
    
    func progress(progress: Float, inCreatingMovies movieFile: String!, inFolder movieFolder: String!) {
        print("CreatingMovie progress:\(progress)")
        
        if (progress == 100) {
            if (self.showCreateCount < self.currentShowCount) {
                self.createShow(self.showCreateCount)
            }
        }
    }
    
    func progress(progress: Float, inConnectingMovies moviePath: String!) {
        print("ConnectingMovie progress:\(progress)")
        
        if (progress == 100) {
            // todo: rename tmp folder and save to show folder
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let dstPath = "airshow/" + dateFormatter.stringFromDate(now)
            let currentShowFolder = String(format: "aircamera/tmp/%d", self.showCreateCount)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath(currentShowFolder, toPath: dstPath)
            self.showCreateCount++
        }
    }
    
    func progress(progress: Float, inCreatingShow showPath: String!) {
        // todo:progress bar
        print("AddingSoundToMovie progress:\(progress)")
        
        self.progress(progress, ratioOf: 1.0)
        
        if (progress == 100) {
            // todo: rename tmp folder and save to show folder
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let dstPath = "airshow/" + dateFormatter.stringFromDate(now)
            let currentShowFolder = String(format: "aircamera/tmp/%d/show", self.showCreateCount)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath(currentShowFolder, toPath: dstPath)
            self.showCreateCount++
            
            if (self.delegate != nil) {
                self.delegate?.airCameraViewController(self, didFinishAddingAirshowToPath: dstPath)
            }
        }
    }
    
    
    // MARK: - Action
    
    @IBAction func syncWithCamera(sender: AnyObject) {
        // test
        /*
        let folderPath = "/DCIM/IMGS/FLD016"
        
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = folderPath
        // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
        //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
        
        // todo:custom segue
        // memo: not airimagecontroller
        self.presentViewController(airNavigationController, animated: true) { () -> Void in
            print("AirImageCollectionViewController")
        }*/
        
        // TBD
        // auto capture with interval
        self.syncCamera = !self.syncCamera
        if (self.syncCamera) {
            // todo:確実にcurrentSensorInfoを取得できた状態にする
            let currentLocation = CLLocation(latitude: (self.currentSensorInfo?.rawInfo.location.latitude)!, longitude: (self.currentSensorInfo?.rawInfo.location.longitude)!)
            self.cameraCtrl?.setCurrentInfo(currentLocation, heading: (self.currentSensorInfo?.rawInfo.location.trueHeading)!)
            /*
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            self.imageSavePath = "airimage/" + dateFormatter.stringFromDate(now)
            */
            if (self.imageSaveCount == 0 && self.currentShowCount == 0) {
                //FileManager.deleteSubFolder(self.imageSavePath)
                //FileManager.createSubFolder(self.imageSavePath)
                self.setupTmpFolder(self.currentShowCount)
            }
            
            self.latestImageIndex = (self.airFileMan?.latestImageIndex())!
            self.syncCameraTimer = NSTimer.scheduledTimerWithTimeInterval(self.syncInterval, target: self, selector: Selector("captureImage:"), userInfo: nil, repeats: true)
        } else {
            if ((self.syncCameraTimer?.valid) != nil) {
                self.syncCameraTimer?.invalidate()
            }
            // timerが止まっても、imageCaptureのフラグはtrueの可能性がある(30fpsなので、基本ないかも)
            self.imageCapture = false
            self.autoCapture = false
            
            if (self.imageSaveCount > 0) {
                self.createShow(self.currentShowCount)
            }
        }
    }
    
    @IBAction func captureImageAction(sender: AnyObject) {
        // TBD
        // capture still image
        if (self.imageSaveCount == 0 && self.currentShowCount == 0) {
            //FileManager.deleteSubFolder(self.imageSavePath)
            //FileManager.createSubFolder(self.imageSavePath)
            self.setupTmpFolder(self.currentShowCount)
        }
        self.autoCapture = false
        self.imageCapture = true
        self.requestImage()
    }
    
    @IBAction func showCapturedImages(sender: AnyObject) {
        // test
        /*FileManager.createSubFolder("airimage/aircamera/tmp")
        for (var i = 1; i <= 3; i++) {
            let imageName = String(format: "%d.jpg", i)
            let image = UIImage(named: imageName)
            let data = UIImageJPEGRepresentation(image!, 1)
            FileManager.saveData(data, toFile: imageName, inFolder: "airimage/aircamera/tmp")
        }*/
        
        //let folderPath = FileManager.getSubDirectoryPath("airimage/tmp")
        //let folderPath = "airimage/aircamera/tmp"
        
        //let airImageCollectionViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AirImageCollectionViewController") as! AirImageCollectionViewController
        //airImageCollectionViewController.parentDir = folderPath
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = "aircamera/tmp/\(self.currentShowCount)/image/before"
        airImageCollectionViewController.pathType = 1
        // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
        //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
        
        // todo:custom segue
        // memo: not airimagecontroller
        self.presentViewController(airNavigationController, animated: true) { () -> Void in
            print("AirImageCollectionViewController")
        }
    }
    
    @IBAction func closeCamera(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
    
    @IBAction func unwindBackToAirCameraController(unwindSegue: UIStoryboardSegue) {
        // todo:unwindSegue.sourceViewController.isKindOfClass()
    }
}



