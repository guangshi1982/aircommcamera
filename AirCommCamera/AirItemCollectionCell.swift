//
//  AirItemCollectionCell.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/10.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

class AirItemCollectionCell: UICollectionViewCell {
    
    override func layoutSubviews() {
        // set frame of items for insering/moving/deleting in cell.(for bug in iOS6.1?)
    }
    
    override func prepareForReuse() {
        // memo: Method of super class must to be called, because something is proccesed in super class.
        super.prepareForReuse()
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes!) {
        // for custom attributes
        if (layoutAttributes.isKindOfClass(AirItemCollectionLayoutAttributes.self)) {
            let attributes: AirItemCollectionLayoutAttributes = layoutAttributes as! AirItemCollectionLayoutAttributes
            
            // set attributes to cell
        } else {// for other attributes
            
        }
    }
}
