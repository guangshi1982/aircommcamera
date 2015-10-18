//
//  AirShowEditViewController.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/08/15.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

protocol AirShowEditViewControllerDelegate {
    func airShowEditViewController(airShowEditViewController: AirShowEditViewController, didFinishEditingAirshowAtPath: String)
}

class AirShowEditViewController: AirPlayerViewController {
    
    @IBOutlet weak var doneBarButton: UIBarButtonItem?
    
    var delegate: AirShowEditViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("AirShowEditViewController viewDidLoad")

        // Do any additional setup after loading the view.
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
    
    // MARK: Action
    
    @IBAction func doneAction(sender: AnyObject) {
        if (self.delegate != nil) {
            //delegate?.airShowEditViewController(self, didFinishEditingAirshowAtPath: "")
        }
    }
    
    @IBAction func deleteAction(sender: AnyObject) {
        
    }
    
    @IBAction func editAction(sender: AnyObject) {
        
    }
    
    @IBAction func shareAction(sender: AnyObject) {
        
    }
}
