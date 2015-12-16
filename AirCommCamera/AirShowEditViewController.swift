//
//  AirShowEditViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/15.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

protocol AirShowEditViewControllerDelegate {
    func airShowEditViewController(airShowEditViewController: AirShowEditViewController, didFinishEditingAirshowAtPath path: String)
    
    func airShowEditViewController(airShowEditViewController: AirShowEditViewController, didFinishDeletingAirshowAtPath path: String)
}

class AirShowEditViewController: AirPlayerViewController {
    
    let identifierAirPreviewController = "AirPreviewController"
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem?
    
    var airShowFolder: String?
    
    var delegate: AirShowEditViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirShowEditViewController viewDidLoad")

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.updateVideo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        print("identifier: \(segue.identifier)")
        if segue.identifier == identifierAirPreviewController {
            let airPreviewController = segue.destinationViewController as! AirPreviewController
            airPreviewController.previewPath = sender as? String
        }
    }
    // MARK: Action
    
    @IBAction func doneAction(sender: AnyObject) {
        if (self.delegate != nil) {
            //delegate?.airShowEditViewController(self, didFinishEditingAirshowAtPath: "")
        }
    }
    
    @IBAction func previewAction(sender: AnyObject) {
        self.performSegueWithIdentifier(self.identifierAirPreviewController, sender: self.videoPath)
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "Delete movie", message: "Delete this movie?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let deleteButtonAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Default) { (action) -> Void in
            print("Delete")
            
            FileManager.deleteFolderWithAbsolutePath(self.airShowFolder)
            if (self.delegate != nil) {
                self.delegate?.airShowEditViewController(self, didFinishDeletingAirshowAtPath: self.airShowFolder!)
            }
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        
        let cancelButtonAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            print("Cancel")
            //FileManager.deleteSubFolder("airfolder/tmp")
        }
        
        actionSheet.addAction(deleteButtonAction)
        actionSheet.addAction(cancelButtonAction)
        
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            print("Action Sheet")
        }
    }
    
    @IBAction func editAction(sender: AnyObject) {
        
    }
    
    @IBAction func shareAction(sender: AnyObject) {
        let videoLink = NSURL(fileURLWithPath: self.videoPath!)
        //let items = ["test", videoLink]
        let items = [videoLink, "test"]
        let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activityViewController.setValue("Share video", forKey: "Subject")
        activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if (completed) {
                print("completed")
            }
        }
        
        self.presentViewController(activityViewController, animated: true) { () -> Void in
            print("UIActivityViewController")
        }
    }
}
