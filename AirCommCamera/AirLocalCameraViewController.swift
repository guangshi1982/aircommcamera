//
//  AirLocalCameraViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

enum AirLocationDirection: Int {
    case None
    case North
    case East
    case South
    case West
}

class AirImagePlaceInfo: NSObject {
    var direction: AirLocationDirection = .North // とりあえず8方向
    var airImage: AirImage?
}

class AirImageTimeInfo: NSObject {
    var dateTime: NSDate?
    var placeInfoList: [AirImagePlaceInfo] = []
}

class AirCameraController: NSObject {
    // 同じ場所での時間系列の
    //var currentInfoList: [AirImageTimeInfo] = []
    //var lastTimeInfo: AirImageTimeInfo?
    var capturedDirectionList: [AirLocationDirection] = []
    
    var lastPlace: CLLocation?
    var lastDirection: AirLocationDirection?
    var lastTime: NSDate?
    
    var captureDistance: Double = 20 // m
    var captureTime: Double = 180 // s
    
    override init() {
        super.init()
        
        self.lastPlace = CLLocation()
        self.lastDirection = AirLocationDirection.None
        self.lastTime = NSDate()
        self.captureDistance = 20
        self.captureTime = 180
    }
    
    convenience init(place: CLLocation, heading: CLLocationDirection, distance: Double, time: Double) {
        self.init()
        
        self.lastPlace = place
        self.lastDirection = self.getDirection(heading)
        self.lastTime = NSDate()
        self.captureDistance = distance
        self.captureTime = time
    }
    
    private func getDirection(headingValue: CLLocationDirection) -> AirLocationDirection {
        var direction = AirLocationDirection.North
        if (headingValue >= 315.0 || headingValue < 45.0) {
            direction = AirLocationDirection.North
        } else if (headingValue >= 45.0 && headingValue < 135.0) {
            direction = AirLocationDirection.East
        } else if (headingValue >= 135.0 && headingValue < 225.0) {
            direction = AirLocationDirection.South
        } else if (headingValue >= 225.0 && headingValue < 315.0) {
            direction = AirLocationDirection.West
        }
        
        return direction
    }
    
    func setCurrentInfo(place: CLLocation, heading: CLLocationDirection) {
        self.lastPlace = place
        self.lastDirection = self.getDirection(heading)
        self.lastTime = NSDate()
    }
    
    // 場所、時間、方向を判断して似た画像をキャプチャしない。todo:さらに前後画像を比較する。
    func canCaptureCurrentImage(sensorInfo: AirSensorInfo) -> Bool {
        var capture = false
        
        let currentPlace = CLLocation(latitude: sensorInfo.rawInfo.location.latitude, longitude: sensorInfo.rawInfo.location.longitude)
        let distance = currentPlace.distanceFromLocation(self.lastPlace!)
        print("distance:\(distance)")
        if (distance > self.captureDistance) {
            capture = true
            self.lastPlace = currentPlace
            self.lastTime = NSDate()
            self.capturedDirectionList = []
            let currentDirection = self.getDirection(sensorInfo.rawInfo.location.trueHeading)
            self.capturedDirectionList.append(currentDirection)
        } else {
            let now = NSDate()
            let time = now.timeIntervalSinceDate(self.lastTime!)
            print("time:\(time)")
            if (time > self.captureTime) {
                capture = true
                self.lastTime = now
                self.capturedDirectionList = []
                let currentDirection = self.getDirection(sensorInfo.rawInfo.location.trueHeading)
                self.capturedDirectionList.append(currentDirection)
            } else {
                // 方向判断
                let currentDirection = self.getDirection(sensorInfo.rawInfo.location.trueHeading)
                print("currentDirection:\(currentDirection)")
                var found = false
                //self.lastDirection = currentDirection
                for direction in self.capturedDirectionList {
                    if (currentDirection == direction) {
                        found = true
                        break
                    }
                }
                if (!found) {
                    capture = true
                    self.capturedDirectionList.append(currentDirection)
                }
            }
        }
        
        return capture
    }
    
    // for AirCamera
    // todo:手ぶれ判断。
    func canSaveCurrentImage(image: UIImage) -> Bool {
        var save = true;
        
        return save
    }
    
    // for iPhone camera
    // todo:手ぶれ判断。センサー情報、露出(bias value)、画像処理(ぶれているか判断可能？前後frameも見る)
    func canSaveCurrentImage(imageInfos: [CaptureImageInfo], sensorInfo: AirSensorInfo, cameraSetting: CameraSetting) -> Bool {
        var save = true
        
        if (abs(cameraSetting.offset) > 4) {
            print("cameraSetting.offset:\(cameraSetting.offset)")
            save = false
        }
        
        return save
    }
    
    // todo:
    func saveCurrentImage(imageInfo: CaptureImageInfo) {
        // 手ぶれ補正
        
        // 画像保存か動画作成
    }
}

// todo: from AirCameraViewController?
class AirLocalCameraViewController: UIViewController, CameraCaptureObserver, AirSensorObserver, AirShowObserver {
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirImageNavigationController = "AirImageNavigationController"
    let identifierAirProgressViewController = "AirProgressViewController"
    let identifierAirShowCollectionViewController = "AirShowCollectionViewController"
    
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.aircomm.image-save"
    
    let MAX_FRAME_COUNT_FOR_SAVE: UInt = 3 // 保存判断用最大frame数
    let MAX_FRAME_COUNT_FOR_MOVIE: UInt = 2
    
    @IBOutlet weak var capturedImageView : UIImageView! = nil
    @IBOutlet weak var saveView: UIView! = nil
    @IBOutlet weak var saveImageView: UIImageView! = nil
    @IBOutlet weak var graphView: AirGraphView! = nil
    @IBOutlet weak var sensorSegControl: UISegmentedControl! = nil
    
    
    @IBOutlet weak var headingLabel: UILabel! = nil
    @IBOutlet weak var headingXYZLabel: UILabel! = nil
    @IBOutlet weak var directionLabel: UILabel! = nil
    @IBOutlet weak var accelerationLabel: UILabel! = nil
    @IBOutlet weak var rotationPitchLabel: UILabel! = nil
    @IBOutlet weak var rotationRollLabel: UILabel! = nil
    @IBOutlet weak var rotationYawLabel: UILabel! = nil
    
    @IBOutlet weak var confidenceLabel: UILabel! = nil
    @IBOutlet weak var unknownLabel: UILabel! = nil
    @IBOutlet weak var stationaryLabel: UILabel! = nil
    @IBOutlet weak var walkingLabel: UILabel! = nil
    @IBOutlet weak var runningLabel: UILabel! = nil
    @IBOutlet weak var automotiveLabel: UILabel! = nil
    @IBOutlet weak var cyclingLabel: UILabel! = nil
    
    @IBOutlet weak var sensorAccelerationButton: UIButton! = nil
    @IBOutlet weak var sensorRotationRateButton: UIButton! = nil
    @IBOutlet weak var sensorLocationButton: UIButton! = nil
    @IBOutlet weak var sensorActivityButton: UIButton! = nil
    
    var airShowMan: AirShowManager? = nil
    var cameraCap: CameraCapture? = nil
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
    
    var imageSaveQueue: dispatch_queue_t?
    var syncCameraTimer: NSTimer?
    
    var imageSavePath: String? = "localcamera/tmp/image/before"
    // todo:create movie when capture image
    var movieMakePath: String? = "localcamera/tmp/movie"
    var imageSaveCount: UInt = 0 // 保存済み画像数
    var showCreateCount: UInt = 0 // 作成済みスライド数
    var currentShowCount: UInt = 0 // 現在作成中スライド番号
    var imageFrameCount: UInt = 0 // 保存対象frame数
    
    var currentSensorInfo: AirSensorInfo?
    var currentCameraSetting: CameraSetting?
    
    var sensorAccelerationStart: Bool = false
    var sensorRotationRateStart: Bool = false
    var sensorLocationStart: Bool = false
    var sensorActivityStart: Bool = false
    
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
    
    // memo:自動回転禁止。ただ、下記のメソッドをoverrideしないと、本viewに入る前の回転方向のままになる
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    // memo:常にportrait(user interface orientaionサポート範囲内(info.plist))
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
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
        FileManager.deleteSubFolder("localcamera/tmp/")
        
        self.airShowMan = AirShowManager.getInstance()
        self.airShowMan!.observer = self
        
        self.currentSensorInfo = AirSensorInfo()
        self.cameraCtrl = AirCameraController()
        self.setupCamera()
        self.setupSensor()
        self.graphView.setSensorType(AirSensorTypeAcceleration)
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            var cameraSettings = CameraSetting()
            cameraSettings.mode = CameraMode.Auto
            cameraSettings.orientaion = CameraOrientaion.Landscape
            // todo:Onの場合、結構遅延が発生。表示が遅いか、frame数が足りない(か遅い)か確認。接近時ONでも良いかも
            // On時どれくらい手ぶれを軽減できるかも確認
            cameraSettings.isMode = CameraImageStabilizationMode.Off
            cameraSettings.type = CameraDataType.Pixel
            cameraSettings.pixelFormat = CameraPixelFormatType.BGRA
            self.cameraCap = CameraCapture.getInstance()
            self.cameraCap!.imageView = self.capturedImageView
            self.cameraCap!.validRect = self.capturedImageView.bounds
            self.cameraCap!.cameraObserver = self
            // todo: set with setting config from ConfigManager
            self.cameraCap!.setupCaptureDeviceWithSetting(cameraSettings)
            self.captureSetup = true
        }
    }
    
    private func setupSensor() {
        self.sensorMan = AirSensorManager.getInstance()
        self.sensorMan?.observer = self
        self.sensorMan?.addSensorType(AirSensorTypeProximity)
        self.sensorMan?.addSensorType(AirSensorTypeLocation)
        self.sensorMan?.addSensorType(AirSensorTypeHeading)
        self.sensorMan?.addSensorType(AirSensorTypeAcceleration)
        self.sensorMan?.addSensorType(AirSensorTypeGyro)
        self.sensorMan?.addSensorType(AirSensorTypeAttitude)
    }
    
    private func setupTmpFolder(folderNum: UInt) {
        //if (folderNum == 0) {
        //    FileManager.deleteSubFolder("localcamera/tmp/")
        //}
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/image/before")// original images
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/image/after")// for effect
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/movie") // none effect(from images with ). And connected movie named [airmovie.xxx]
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/transform") // transition
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/sound") // connected movie from movies (no sound)
        FileManager.createSubFolder("localcamera/tmp/\(folderNum)/show")
    }
    
    private func saveCapturedImage(image: UIImage?) {
        if (image != nil) {
            // memo:PNGの場合、orientationの情報が消える？ので。
            let data = UIImageJPEGRepresentation(image!, 0.5)
            //let data = UIImagePNGRepresentation(info.image!)// not dImage
            if (data == nil) {
                print("data is nil")
            }
            //let now = NSDate()
            // @memo double->string
            //let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
            let imageNameExt = String(format:"image_%d.png", self.imageSaveCount)
            // todo:save to sub folder of airimage
            FileManager.saveData(data, toFile: imageNameExt, inFolder: "localcamera/tmp/\(self.currentShowCount)/image/before")
        }
    }
    
    private func saveImageFromSampleBuffer(sampleBuffer: CMSampleBufferRef?, transform: CGAffineTransform) {
        if (sampleBuffer != nil) {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer!)
            CVPixelBufferLockBaseAddress(pixelBuffer!, 0)
            
            let width = CVPixelBufferGetWidth(pixelBuffer!)
            let height = CVPixelBufferGetHeight(pixelBuffer!)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer!)
            let base = CVPixelBufferGetBaseAddress(pixelBuffer!)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            // varにすると.rawValueが見れない
            let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue) as UInt32)
            let cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, bitmapInfo.rawValue)
            // 下記もOK
            //let cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
            let cgImage = CGBitmapContextCreateImage(cgContext)
            // todo:Deviceのorientation情報が入っていないのでNG.transformで判断
            let image = UIImage(CGImage: cgImage!, scale: UIScreen.mainScreen().scale, orientation: self.imageOrientationFromCaptureOrientation((self.currentCameraSetting?.orientaion)!))
            
            // memo:PNGの場合、orientationの情報が消える？ので。
            let data = UIImageJPEGRepresentation(image, 0.5)
            //let data = UIImagePNGRepresentation(info.image!)// not dImage
            if (data == nil) {
                print("data is nil")
            }
            //let now = NSDate()
            // @memo double->string
            //let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
            let imageNameExt = String(format:"image_%d.png", self.imageSaveCount)
            // todo:save to sub folder of airimage
            FileManager.saveData(data, toFile: imageNameExt, inFolder: "localcamera/tmp/\(self.currentShowCount)/image/before")
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer!, 0)
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBufferRef, imageOrientation: UIImageOrientation) -> UIImage {
        //let imageBuffer: CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        let base = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, CGBitmapInfo.ByteOrder32Little.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue)
        let cgImage = CGBitmapContextCreateImage(cgContext)
        // todo:Deviceのorientation情報が入っていないのでNG.transformで判断
        // memo:画像サイズが半分になっちゃう(bufferサイズは変わらない)
        //let image = UIImage(CGImage: cgImage!, scale: UIScreen.mainScreen().scale, orientation: imageOrientation)
        // 0か1設定。todo:違いは?
        let image = UIImage(CGImage: cgImage!, scale: 0, orientation: imageOrientation)
        //CGColorSpaceRelease(colorSpace)// todo:error!不要。下同
        //CGContextRelease(cgContext)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return image
    }
    
    private func sampleBufferToMovie(sampleBuffer: CMSampleBufferRef, transform: CGAffineTransform) {
        let pixelBuffer: CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let airFrame = AirFrame(pixelBuffer: pixelBuffer, transform: transform)
        // todo:Folder作成
        let moviePath = FileManager.getPathWithFileName(String(format: "%d.mov", self.imageSaveCount), fromFolder: "localcamera/tmp/\(self.currentShowCount)/movie")
        self.airShowMan!.createAirMovieWithAirFrame(airFrame, movie: moviePath)
    }
    
    private func createMovie(image: AirImage?) {
        // todo:キャプチャされた映像サイズが960x540になっている。bufferは19201080だが。実際の動画サイズ、画質に影響あるのか？->image作成時screen.scaleを設定したので
        //let imagePath = FileManager.getPathWithFileName(String(format: "image_%d.png", self.imageSaveCount), fromFolder: "localcamera/tmp/image/before")
        //let airImage = AirImage(path: imagePath)
        // todo:Folder作成
        //let moviePath = FileManager.getPathWithFileName(String(format: "%d.mov", self.imageSaveCount), fromFolder: "localcamera/tmp/\(self.currentShowCount)/movie")
        self.airShowMan?.createAirMovieWithAirImage(image, movie: String(format: "%d.mov", self.imageSaveCount), inFolder: "localcamera/tmp/\(self.currentShowCount)/movie")
        
        // todo: AirImageにfileNameがないので...
        //let airImages: [AirImage] = [image!]
        //self.airShowMan?.createAirMoviesWithAirImages(airImages, movies: "localcamera/tmp/\(self.currentShowCount)/movie")
        
    }
    
    private func createShow(showNum: UInt) {
        //let dstPath = String(format: "localcamera/%d", self.currentShowCount + 1)
        //FileManager.copyFromPath("localcamera/tmp", toPath: dstPath)
        
        var airMovies: [AirMovie] = []
        let filePaths: [String]? = FileManager.getFilePathsInSubDir("localcamera/tmp/\(showNum)/movie") as? [String]
        if filePaths != nil {
            for filePath in filePaths! {
                let airMovie: AirMovie = AirMovie(path: filePath)
                airMovies.append(airMovie)
            }
        }
        
        // todo:とりあえずsoundなし
        let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: "localcamera/tmp/\(showNum)/show")
        self.airShowMan!.connectAirMovies(airMovies, movie: showPath)
        
        /*
        let soundPath = NSBundle.mainBundle().pathForResource("dream", ofType:"mp3")
        let airSound: AirSound = AirSound(path: soundPath)
        let showPath = FileManager.getPathWithFileName("airshow.mov", fromFolder: "localcamera/tmp/\(showNum)/show")
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
    }
    
    func startCapture() {
        if (self.captureStart == false) {
            self.cameraCap?.startCapture()
            self.captureStart = true
        }
    }
    
    func stopCapture() {
        if (self.captureStart) {
            self.cameraCap?.stopCapture()
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
    
    // MARK: - CameraCaptureObserver protocol
    
    func captureImageInfo(info: CaptureImageInfo!) {
        // キャプチャされた映像サイズが960x540になっている。bufferは19201080だが。勝手にcropされる?->下記image作成でScreen.scaleを設定したので...
        let imageCaptured: UIImage = self.imageFromSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
        // todo:1frame?3frame?
        if (self.imageCapture) {
            self.imageCapture = false
            // @memo:非同期なので、最大画像数まで制限しないと、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
            // 設定間隔内で処理が完了するはずなので、非同期にしてみる
            //dispatch_async(self.imageSaveQueue!, { () -> Void in
            dispatch_sync(self.imageSaveQueue!, { () -> Void in// todo:infoは参照になっているので、非同期の場合、解放されてしまう。とりあえず同期に
                var canCapture: Bool = true
                if (self.autoCapture) {
                    canCapture = (self.cameraCtrl?.canCaptureCurrentImage(self.currentSensorInfo!))!
                }
                print("canCapture:\(canCapture)")
                if (canCapture) {
                    var canSave: Bool = true
                    if (self.autoCapture) {
                        canSave = (self.cameraCtrl?.canSaveCurrentImage([info], sensorInfo: self.currentSensorInfo!, cameraSetting: self.currentCameraSetting!))!
                    }
                    if (canSave) {
                        //self.saveCapturedImage(info.image)
                        //imageCaptured = self.imageFromSampleBuffer(info.sampleBuffer, imageOrientation: info.orientation)
                        self.saveCapturedImage(imageCaptured)
                        // todo:AirFrameのprogress:inCreatingMovies対応
                        //self.sampleBufferToMovie(info.sampleBuffer, transform: info.transfrom)
                        let airImage = AirImage(image: imageCaptured)
                        self.createMovie(airImage)// OK
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
    
    func currentSettingChanged(settings: CameraSetting) {
        self.currentCameraSetting = settings
    }
    
    // MARK: - AirSensorObserver protocol
    
    func capture(info: AirSensorInfo!) {
        
    }
    
    func displayCameraView(flag: Bool, info: AirSensorInfo!) {
        //self.dispImage = !flag
        // todo: test
        self.dispImage = false
        if (self.dispImage) {
            // 画面表示時は変換済みの画像データ
            self.cameraCap?.changeCameraDataType(CameraDataType.Image)
            // todo:手ぶれOff?
        } else {
            // 画面非表示時はpixelデータ
            self.cameraCap?.changeCameraDataType(CameraDataType.Pixel)
            // todo:手ぶれON?
        }
    }
    
    func sensorInfo(info: AirSensorInfo!, ofType type: AirSensorType) {
        
        self.currentSensorInfo = info
        
        if (self.dispSensorGraph) {
            if (type == AirSensorTypeAcceleration) {
                self.graphView.addAccelerationData(info.rawInfo.acceleration)
            } else if (type == AirSensorTypeGyro) {
                self.graphView.addGyroData(info.rawInfo.rotation)
            } else if (type == AirSensorTypeAttitude) {
                self.graphView.addAttitudeData(info.rawInfo.rotation)
            }
        }
        
        
        #if false
            
        let headingValue: Double = info.rawInfo.location.magneticHeading
        var direction: String = ""
            
        // memo:固まる!!sensorからのコールバックはすでにmain queueのthreadになっている?
        /*dispatch_sync(dispatch_get_main_queue(), { () -> Void in
        self.headinglabel.text = heading
        self.accelerationlabel.text = acceleration
        self.rotationlabel.text = rotation
        })*/
        
        if (headingValue >= 0.0 && headingValue < 90.0) {
            let subValue = 90.0 - headingValue
            direction = String(format: "N(%.2f)", subValue)
        } else if (headingValue >= 90.0 && headingValue < 180.0) {
            let subValue = 180.0 - headingValue
            direction = String(format: "E(%.2f)", subValue)
        } else if (headingValue >= 180.0 && headingValue < 270.0) {
            let subValue = 270.0 - headingValue
            direction = String(format: "S(%.2f)", subValue)
        } else if (headingValue >= 270.0 && headingValue < 360.0) {
            let subValue = 360.0 - headingValue
            direction = String(format: "W(%.2f)", subValue)
        }
        
        //dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.headingLabel.text = String(format: "%.2f", headingValue)
            self.headingXYZLabel.text = String(format: "%.2f, %.2f, %.2f", info.rawInfo.location.headingX, info.rawInfo.location.headingY, info.rawInfo.location.headingZ)
            self.directionLabel.text = direction
            self.accelerationLabel.text = String(format: "%.2f, %.2f, %.2f", info.rawInfo.acceleration.x, info.rawInfo.acceleration.y, info.rawInfo.acceleration.z)
            self.rotationPitchLabel.text = String(format: "%.2f(%.2f)", info.rawInfo.rotation.pitch, info.rawInfo.rotation.x)
            self.rotationRollLabel.text = String(format: "%.2f(%.2f)", info.rawInfo.rotation.roll, info.rawInfo.rotation.y)
            self.rotationYawLabel.text = String(format: "%.2f(%.2f)", info.rawInfo.rotation.yaw, info.rawInfo.rotation.z)
            
            self.confidenceLabel.text = String(format: "confidence:%d", info.rawInfo.activity.confidence)
            self.unknownLabel.text = String(format: "%@", info.rawInfo.activity.unknown == true ? "unknown" : "-")
            self.stationaryLabel.text = String(format: "%@", info.rawInfo.activity.stationary == true ? "stationary" : "-")
            self.walkingLabel.text = String(format: "%@", info.rawInfo.activity.walking == true ? "walking" : "-")
            self.runningLabel.text = String(format: "%@", info.rawInfo.activity.running == true ? "running" : "-")
            self.automotiveLabel.text = String(format: "%@", info.rawInfo.activity.automotive == true ? "automotive" : "-")
            self.cyclingLabel.text = String(format: "%@", info.rawInfo.activity.cycling == true ? "cycling" : "-")
        //}
        #endif
        
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
            let currentShowFolder = String(format: "localcamera/tmp/%d", self.showCreateCount)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath(currentShowFolder, toPath: dstPath)
            self.showCreateCount++
        }
    }
    
    // todo: sound追加しないので、現状呼ばれない
    func progress(progress: Float, inCreatingShow showPath: String!) {
        // todo:progress bar
        print("AddingSoundToMovie progress:\(progress)")
        
        if (progress == 100) {
            // todo: rename tmp folder and save to show folder
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            let dstPath = "airshow/" + dateFormatter.stringFromDate(now)
            let currentShowFolder = String(format: "localcamera/tmp/%d/show", self.showCreateCount)
            //FileManager.createSubFolder(dstPath)
            FileManager.copyFromPath(currentShowFolder, toPath: dstPath)
            self.showCreateCount++
        }
    }
    
    // MARK: - Action
    
    @IBAction func syncWithCameraAction(sender: AnyObject) {
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
    }
    
    // memo:gestureの場合、対象viewのUser Interaction Eabledがtrueになる必要がある
    @IBAction func showCapturedImagesAction(sender: AnyObject) {
        //let airImageCollectionViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AirImageCollectionViewController") as! AirImageCollectionViewController
        //airImageCollectionViewController.parentDir = folderPath
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = "localcamera/tmp/\(self.currentShowCount)/image/before"
        airImageCollectionViewController.pathType = 0
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
    
    @IBAction func unwindBackToLocalCameraController(unwindSegue: UIStoryboardSegue) {
        // todo:unwindSegue.sourceViewController.isKindOfClass()
    }
    
    @IBAction func sensorGraphChanged(sender: AnyObject) {
        let segCtrl = sender as! UISegmentedControl
        var sensorType = AirSensorTypeNone
        
        switch (segCtrl.selectedSegmentIndex) {
        case 0:
            sensorType = AirSensorTypeNone
            break;
        case 1:
            sensorType = AirSensorTypeAcceleration
            break;
        case 2:
            sensorType = AirSensorTypeGyro
            break;
        case 3:
            sensorType = AirSensorTypeAttitude
            break;
        default:
            sensorType = AirSensorTypeNone
        }
        
        self.graphView.setSensorType(sensorType)
        
        if (sensorType == AirSensorTypeNone) {
            self.dispSensorGraph = false
            // todo:test
            self.stopSensor()
        } else {
            self.dispSensorGraph = true
            // todo:test
            self.startSensor()
            self.graphView.setSensorType(sensorType)
        }
        
        self.graphView.hidden = !self.dispSensorGraph
    }
    
    @IBAction func sensorAccelerationButtonClicked(sender: AnyObject) {
        print("sensorAccelerationStart: \(self.sensorAccelerationStart)")
        if (self.sensorAccelerationStart == false) {
            self.sensorMan?.addSensorType(AirSensorTypeAcceleration)
            self.sensorMan?.start()
            self.sensorAccelerationButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorAccelerationStart = true
        } else {
            self.sensorMan?.stop()
            self.sensorAccelerationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorAccelerationStart = false
        }
    }
    
    @IBAction func sensorRotationRateButtonClicked(sender: AnyObject) {
        print("sensorRotationRateStart: \(self.sensorRotationRateStart)")
        if (self.sensorRotationRateStart == false) {
            self.sensorMan?.addSensorType(AirSensorTypeRotationRate)
            self.sensorMan?.start()
            self.sensorRotationRateButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorRotationRateStart = true
        } else {
            self.sensorMan?.stop()
            self.sensorRotationRateButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorRotationRateStart = false
        }
    }
    
    @IBAction func sensorLocationButtonClicked(sender: AnyObject) {
        print("sensorLocationStart: \(self.sensorLocationStart)")
        if (self.sensorLocationStart == false) {
            self.sensorMan?.addSensorType(AirSensorTypeLocation)
            self.sensorMan?.start()
            self.sensorLocationButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorLocationStart = true
        } else {
            self.sensorMan?.stop()
            self.sensorLocationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorLocationStart = false
        }
    }
    
    @IBAction func sensorActivityButtonClicked(sender: AnyObject) {
        print("sensorActivityStart: \(self.sensorActivityStart)")
        if (self.sensorActivityStart == false) {
            self.sensorMan?.addSensorType(AirSensorTypeActivity)
            self.sensorMan?.start()
            self.sensorActivityButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorActivityStart = true
        } else {
            self.sensorMan?.stop()
            self.sensorActivityButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorActivityStart = false
        }
    }
}