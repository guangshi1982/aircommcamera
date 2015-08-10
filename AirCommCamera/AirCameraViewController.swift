//
//  AirCameraViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/06.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class AirCameraViewController: UIViewController, CameraCaptureObserver, AirSensorObserver {
    let QUEUE_SERIAL_IMAGE_SAVE = "com.threees.aircomm.image-save"
    
    @IBOutlet weak var captureImageView : UIImageView! = nil
    
    var cameraCap: CameraCapture? = nil
    var captureSetup: Bool = false
    var captureStart: Bool = false
    var saveImage: Bool = false
    
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
        self.setupCamera()
    }
    
    private func setupCamera() {
        if (self.captureSetup == false) {
            var cameraSettings = CameraSetting()
            self.cameraCap = CameraCapture.getInstance()
            self.cameraCap!.imageView = self.captureImageView
            self.cameraCap!.validRect = self.captureImageView.bounds
            self.cameraCap!.cameraObserver = self
            // todo: set with setting config from ConfigManager
            self.cameraCap!.setupCaptureDeviceWithSetting(cameraSettings)
            self.captureSetup = true
        }
    }
    
    @IBAction func start(sender: AnyObject) {
        self.startCapture()
    }
    
    @IBAction func stop(sender: AnyObject) {
        self.stopCapture()
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
                var saveImage = info.image
                //let data = UIImageJPEGRepresentation(dImage, 0.5)
                let data = UIImagePNGRepresentation(saveImage)// not dImage
                if (data == nil) {
                    println("data is nil")
                }
                let now = NSDate()
                // @memo double->string
                let imageNameExt = String(format:"image_%.3f.png", now.timeIntervalSince1970)
                // todo:save to sub folder of airimage
                if (!FileManager.saveData(data, toFile: imageNameExt, inFolder: "/airimage")) {
                    println("image save error")
                }
            })
        }
        
        // @memo: queue in UI thread
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.captureImageView.image = info.image
        }
    }
    
    // MARK: - AirSensorObserver protocol
    
    func captureImage(flag: Bool, rawInfo: AirSensorRawInfo) {
        
    }
}
