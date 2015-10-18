//
//  AirItemCollectionLayoutAttributes.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/10.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class AirItemCollectionLayoutAttributes: UICollectionViewLayoutAttributes {
    // add any custom attribute
    
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        var airItemAttributes: AirItemCollectionLayoutAttributes = super.copyWithZone(zone) as! AirItemCollectionLayoutAttributes
        // set attributes that added for customizing
        
        return airItemAttributes
    }
}
