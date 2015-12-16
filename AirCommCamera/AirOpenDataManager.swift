//
//  AirOpenDataManager.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/11/15.
//  Copyright © 2015年 Threees. All rights reserved.
//

import UIKit

class AirOpenDataManager: NSObject {
    static let opendata_url_1_host = "https://www.chiikinogennki.soumu.go.jp"
    static let opendata_url_1_path_root = "k-cloud-api"
    static let opendata_url_1_version = "v001"
    static let opendata_url_1_genre_kanko = "kanko"
    static let opendata_url_common_format_json = "json"
    
    class func getTouristData(latitude: Double, longitude: Double, keyword: String?) {
    
    }
    
    private class func createUrl() -> String {
        var url = opendata_url_1_host + "/" + opendata_url_1_path_root
        
        return url
    }
}
