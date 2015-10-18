//
//  AirLocalCameraViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

// todo: from AirCameraViewController?
class AirLocalCameraViewController: UIViewController, CameraCaptureObserver, AirSensorObserver {
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.aircomm.image-save"
    
    @IBOutlet weak var captureImageView : UIImageView! = nil
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
    var captureSetup: Bool = false
    var captureStart: Bool = false
    var saveImage: Bool = false
    var sensorAccelerationStart: Bool = false
    var sensorRotationRateStart: Bool = false
    var sensorLocationStart: Bool = false
    var sensorActivityStart: Bool = false
    
    var imageSaveQueue: dispatch_queue_t?
    
    override func viewDidLoad() {
        Log.debug("CaputureView viewDidLoad")
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        Log.debug("CaputureView viewWillAppear")
        super.viewWillAppear(animated)
        
        // アプリ内画面切替時（例えば、設定画面から戻った場合）。アプリバック->再開では呼ばれない
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
        //        self.setupCamera()
        self.setupSensor()
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            let cameraSettings = CameraSetting()
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
        // todo:
        if (self.saveImage) {
            dispatch_async(self.imageSaveQueue!, { () -> Void in // @memo:非同期なので、最大画像数まで制限しないと、キューで待機されるとき、メモリが増え続ける。警告発生して落ちる!?
                //dispatch_sync(self.imageSaveQueue!, { () -> Void in
                let saveImage = info.image
                //let data = UIImageJPEGRepresentation(dImage, 0.5)
                let data = UIImagePNGRepresentation(saveImage)// not dImage
                if (data == nil) {
                    print("data is nil")
                }
                let now = NSDate()
                // @memo double->string
                let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
                // todo:save to sub folder of airimage
                if (!FileManager.saveData(data, toFile: imageNameExt, inFolder: "/airimage")) {
                    print("image save error")
                }
            })
        }
        
        // @memo: queue in UI thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.captureImageView.image = info.image
        }
    }
    
    // MARK: - AirSensorObserver protocol
    
    func captureImage(flag: Bool, info: AirSensorInfo!) {
        
    }
    
    func sensorInfo(info: AirSensorInfo!) {
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
    }
    
    // MARK: - Action
    
    @IBAction func syncWithCamera(sender: AnyObject) {
        
    }
    
    @IBAction func showCapturedImages(sender: AnyObject) {
        
    }
    
    @IBAction func closeCamera(sender: AnyObject) {
        
    }
    
    @IBAction func sensorAccelerationButtonClicked(sender: AnyObject) {
        print("sensorAccelerationStart: \(self.sensorAccelerationStart)")
        if (self.sensorAccelerationStart == false) {
            self.sensorMan?.start(AirSensorTypeAcceleration)
            self.sensorAccelerationButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorAccelerationStart = true
        } else {
            self.sensorMan?.stop(AirSensorTypeAcceleration)
            self.sensorAccelerationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorAccelerationStart = false
        }
    }
    
    @IBAction func sensorRotationRateButtonClicked(sender: AnyObject) {
        print("sensorRotationRateStart: \(self.sensorRotationRateStart)")
        if (self.sensorRotationRateStart == false) {
            self.sensorMan?.start(AirSensorTypeRotationRate)
            self.sensorRotationRateButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorRotationRateStart = true
        } else {
            self.sensorMan?.stop(AirSensorTypeRotationRate)
            self.sensorRotationRateButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorRotationRateStart = false
        }
    }
    
    @IBAction func sensorLocationButtonClicked(sender: AnyObject) {
        print("sensorLocationStart: \(self.sensorLocationStart)")
        if (self.sensorLocationStart == false) {
            self.sensorMan?.start(AirSensorTypeLocation)
            self.sensorLocationButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorLocationStart = true
        } else {
            self.sensorMan?.stop(AirSensorTypeLocation)
            self.sensorLocationButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorLocationStart = false
        }
    }
    
    @IBAction func sensorActivityButtonClicked(sender: AnyObject) {
        print("sensorActivityStart: \(self.sensorActivityStart)")
        if (self.sensorActivityStart == false) {
            self.sensorMan?.start(AirSensorTypeActivity)
            self.sensorActivityButton.setTitle("stop", forState: UIControlState.Normal)
            self.sensorActivityStart = true
        } else {
            self.sensorMan?.stop(AirSensorTypeActivity)
            self.sensorActivityButton.setTitle("start", forState: UIControlState.Normal)
            self.sensorActivityStart = false
        }
    }
    
    @IBAction func cameraCloseButtonClicked(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            print("dismissViewController")
        })
    }
}