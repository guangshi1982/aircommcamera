//
//  Util.swift
//  LEDSignalDetector
//
//  Created by 文 光石 on 2015/02/22.
//  Copyright (c) 2015年 TrE. All rights reserved.
//

import Foundation

struct DateInfo {
    var year = 0
    var month = 0
    var day = 0
    var hour = 0
    var minute = 0
    var second = 0
}

class TSUtil {
    class func gcd(var x: Int, var y: Int) -> Int {
        if (x == 0 || y == 0) {// 引数チェック
            return 0
        }
    
        // ユーグリッドの互除法
        var r: Int = x % y
        while (r != 0) {// yで割り切れるまでループ
            x = y
            y = r
            r = x % y
        }
    
        return y
    }
    
    class func lcm( x: Int, y: Int) -> Int {
        if (x == 0 || y == 0) {// 引数チェック
            return 0
        }
    
        return (x * y / TSUtil.gcd(x, y: y))
    }
    
    class func getDateNow() -> DateInfo {
        let now = NSDate()
        
        return TSUtil.getDate(now)
    }
    
    class func getDate( date: NSDate) -> DateInfo {
        let calendar = NSCalendar(identifier: NSCalendarIdentifierGregorian)
        //和暦を使いたいときはidentifierにはNSCalendarIdentifierJapaneseを指定
        //let calendar = NSCalendar(identifier: NSCalendarIdentifierJapanese)
        
        let comps:NSDateComponents = calendar!.components(
            /*NSCalendarUnit.Year |
                NSCalendarUnit.Month |
                NSCalendarUnit.Day |
                NSCalendarUnit.Hour |
                NSCalendarUnit.Minute |*/
                NSCalendarUnit.Second,
            fromDate: date)
        
        var dateInfo = DateInfo()
        dateInfo.year = comps.year
        dateInfo.month = comps.month
        dateInfo.day = comps.day
        dateInfo.hour = comps.hour
        dateInfo.minute = comps.minute
        dateInfo.second = comps.second
        
        return dateInfo
    }
    
    class func getDirWithDate( date: NSDate) -> String {
        let dateInfo = TSUtil.getDate(date)
        let dir = String(format: "%d/%d/%d/%d/%d/%d",
            dateInfo.year,
            dateInfo.month,
            dateInfo.day,
            dateInfo.hour,
            dateInfo.minute,
            dateInfo.second)
        
        return dir
    }
}