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
            let currentDirection = self.getDirection(sensorInfo.rawInfo.location.heading)
            self.capturedDirectionList.append(currentDirection)
        } else {
            let now = NSDate()
            let time = now.timeIntervalSinceDate(self.lastTime!)
            print("time:\(time)")
            if (time > self.captureTime) {
                capture = true
                self.lastTime = now
                self.capturedDirectionList = []
                let currentDirection = self.getDirection(sensorInfo.rawInfo.location.heading)
                self.capturedDirectionList.append(currentDirection)
            } else {
                // 方向判断
                let currentDirection = self.getDirection(sensorInfo.rawInfo.location.heading)
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
    
    func canSaveCurrentImage(image: UIImage, sensorInfo: AirSensorInfo) -> Bool {
        var save = true
        
        return save
    }
}

// todo: from AirCameraViewController?
class AirLocalCameraViewController: UIViewController, CameraCaptureObserver, AirSensorObserver {
    let identifierAirImageCollectionViewController = "AirImageCollectionViewController"
    let identifierAirImageNavigationController = "AirImageNavigationController"
    
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.aircomm.image-save"
    
    @IBOutlet weak var captureImageView : UIImageView! = nil
    @IBOutlet weak var saveView: UIView! = nil
    @IBOutlet weak var saveImageView: UIImageView! = nil
    
    
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
    
    var cameraCap: CameraCapture? = nil
    var sensorMan: AirSensorManager? = nil
    var cameraCtrl: AirCameraController? = nil
    var captureSetup: Bool = false
    var captureStart: Bool = false
    var imageCapture: Bool = false
    var syncCamera: Bool = false
    var syncInterval: NSTimeInterval = 3
    var sensorStart: Bool = false
    var initLocation: Bool = false
    
    var imageSaveQueue: dispatch_queue_t?
    var syncCameraTimer: NSTimer?
    
    var imageSavePath: String? = "airimage/localcamera/tmp"
    var imageSaveCount: Int = 0
    
    var currentSensorInfo: AirSensorInfo?
    var currentCameraSetting: CameraCurrentSetting?
    
    
    var sensorAccelerationStart: Bool = false
    var sensorRotationRateStart: Bool = false
    var sensorLocationStart: Bool = false
    var sensorActivityStart: Bool = false
    
    override func viewDidLoad() {
        Log.debug("CaputureView viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.debug("CaputureView viewWillAppear")
        super.viewWillAppear(animated)
        
        if (self.sensorStart == false) {
            self.sensorMan?.addSensorType(AirSensorTypeProximity)
            self.sensorMan?.addSensorType(AirSensorTypeLocation)
            self.sensorMan?.addSensorType(AirSensorTypeRotationRate)
            self.sensorMan?.start()
            //self.sensorLocationButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorStart = true
        }
        
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
        
        if (self.sensorStart == true) {
            self.sensorMan?.stop()
            //self.sensorLocationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorStart = false
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
    
    private func setup() {
        self.imageSaveQueue = dispatch_queue_create(QUEUE_SERIAL_IMAGE_SAVE, DISPATCH_QUEUE_SERIAL)
        self.currentSensorInfo = AirSensorInfo()
        self.cameraCtrl = AirCameraController()
        self.setupCamera()
        self.setupSensor()
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            var cameraSettings = CameraSetting()
            cameraSettings.mode = CameraMode.Auto
            cameraSettings.orientaion = CameraOrientaion.Default
            self.cameraCap = CameraCapture.getInstance()
            self.cameraCap!.imageView = self.captureImageView
            self.cameraCap!.validRect = self.captureImageView.bounds
            self.cameraCap!.cameraObserver = self
            // todo: set with setting config from ConfigManager
            self.cameraCap!.setupCaptureDeviceWithSetting(cameraSettings)
            self.captureSetup = true
        }
    }
    
    private func setupSensor() {
        self.sensorMan = AirSensorManager.getInstance()
        self.sensorMan?.observer = self
    }
    
    // memo:NSTimerのSelectorの場合、privateにすると落ちる（見つからない?）
    func captureImage(timer: NSTimer) {
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
    
    // MARK: - CameraCaptureObserver protocol
    
    func caputureImageInfo(info: CaputureImageInfo!) {
        // todo:1frame?3frame?
        if (self.imageCapture) {
            self.imageCapture = false
            dispatch_async(self.imageSaveQueue!, { () -> Void in // @memo:非同期なので、最大画像数まで制限しないと、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
                //dispatch_sync(self.imageSaveQueue!, { () -> Void in
                let canCapture: Bool = (self.cameraCtrl?.canCaptureCurrentImage(self.currentSensorInfo!))!
                print("canCapture:\(canCapture)")
                if (canCapture) {
                    if (info.image != nil) {
                        // memo:PNGの場合、orientationの情報が消える？ので。
                        let data = UIImageJPEGRepresentation(info.image!, 0.5)
                        //let data = UIImagePNGRepresentation(info.image!)// not dImage
                        if (data == nil) {
                            print("data is nil")
                        }
                        //let now = NSDate()
                        // @memo double->string
                        //let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
                        let imageNameExt = String(format:"image_%d.png", self.imageSaveCount)
                        // todo:save to sub folder of airimage
                        if (FileManager.saveData(data, toFile: imageNameExt, inFolder: self.imageSavePath)) {
                            self.imageSaveCount++
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) { () -> Void in
                            self.saveImageView.image = info.image
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
        
        // @memo: queue in UI thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.captureImageView.image = info.image
        }
    }
    
    func currentSettingChanged(settings: CameraCurrentSetting) {
        self.currentCameraSetting = settings
    }
    
    // MARK: - AirSensorObserver protocol
    
    func capture(info: AirSensorInfo!) {
        
    }
    
    func sensorInfo(info: AirSensorInfo!, ofType type: AirSensorNotifyType) {
        
        self.currentSensorInfo = info
        
        let headingValue: Double = info.rawInfo.location.heading
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
        
    }
    
    // MARK: - Action
    
    @IBAction func syncWithCameraAction(sender: AnyObject) {
        // TBD
        // auto capture with interval
        self.syncCamera = !self.syncCamera
        if (self.syncCamera) {
            // todo:確実にcurrentSensorInfoを取得できた状態にする
            let currentLocation = CLLocation(latitude: (self.currentSensorInfo?.rawInfo.location.latitude)!, longitude: (self.currentSensorInfo?.rawInfo.location.longitude)!)
            self.cameraCtrl?.setCurrentInfo(currentLocation, heading: (self.currentSensorInfo?.rawInfo.location.heading)!)
            /*
            let now = NSDate()
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_US") // ロケールの設定
            dateFormatter.dateFormat = "yyyy_MM_dd_HH_mm_ss" // 日付フォーマットの設定
            self.imageSavePath = "airimage/" + dateFormatter.stringFromDate(now)
            */
            if (self.imageSaveCount == 0) {
                FileManager.deleteSubFolder(self.imageSavePath)
                //self.imageSaveCount = 0
                FileManager.createSubFolder(self.imageSavePath)
            }
            self.syncCameraTimer = NSTimer.scheduledTimerWithTimeInterval(self.syncInterval, target: self, selector: Selector("captureImage:"), userInfo: nil, repeats: true)
        } else {
            if ((self.syncCameraTimer?.valid) != nil) {
                self.syncCameraTimer?.invalidate()
            }
            // timerが止まっても、imageCaptureのフラグはtrueの可能性がある(30fpsなので、基本ないかも)
            self.imageCapture = false
        }
    }
    
    // memo:gestureの場合、対象viewのUser Interaction Eabledがtrueになる必要がある
    @IBAction func showCapturedImagesAction(sender: AnyObject) {
        //let airImageCollectionViewController = self.storyboard!.instantiateViewControllerWithIdentifier("AirImageCollectionViewController") as! AirImageCollectionViewController
        //airImageCollectionViewController.parentDir = folderPath
        let airNavigationController: UINavigationController = self.storyboard!.instantiateViewControllerWithIdentifier(self.identifierAirImageNavigationController) as! UINavigationController
        let airImageCollectionViewController = airNavigationController.topViewController as! AirImageCollectionViewController
        airImageCollectionViewController.parentDir = self.imageSavePath
        airImageCollectionViewController.pathType = 0
        // memo:storyboardでnavigationcontrollerにrootviewcontrollerを設定していない場合、コード上でcontrollerを作ってpushする
        //airNavigationController.pushViewController(airImageCollectionViewController, animated: false)
        
        // todo:custom segue
        // memo: not airimagecontroller
        self.presentViewController(airNavigationController, animated: true) { () -> Void in
            print("AirImageCollectionViewController")
        }
    }
    
    @IBAction func caputureImageAction(sender: AnyObject) {
        // TBD
        // capture still image
        if (self.imageSaveCount == 0) {
            FileManager.deleteSubFolder(self.imageSavePath)
            //self.imageSaveCount = 0
            FileManager.createSubFolder(self.imageSavePath)
        }
        self.imageCapture = true
    }
    
    @IBAction func closeCamera(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
    
    @IBAction func unwindBackToLocalCameraController(unwindSegue: UIStoryboardSegue) {
        // todo:unwindSegue.sourceViewController.isKindOfClass()
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