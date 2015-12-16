//
//  AirNetworkManager.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/11/15.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

class AirNetworkManager: NSObject {
    let QUEUE_SERIAL_CONNECTION_REQUEST = "com.threees.aircomm.connection-request"
    
    class func requestJsonDataWithUrl(url: String, responseJsonHandler: (NSDictionary?) -> Void) {
        requestDataWithUrl(url, method: "GET") { (data) -> Void in
            do {
                let dict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                responseJsonHandler(dict)
            } catch {
                
            }
        }
    }
    
    private class func requestDataWithUrl(url: String, method: String, responseHandler: (NSData?) -> Void) {
        let reqUrl = NSURL(string: url)
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        let request = NSMutableURLRequest(URL: reqUrl!)
        request.HTTPMethod = method
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if (error != nil) {
                responseHandler(data)
            }
        }
        task.resume()
    }
}
