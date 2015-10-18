//
//  AirItemCollectionSupplementaryView.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/10.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

// todo: Define new string of kind for this supplementary view if necessary.

// Another supplementary view (e.g. header/footer) or Decoration view(mamaged by Layout not data source)
// return kind with class method if necessary.
class AirItemCollectionSupplementaryView: UICollectionReusableView {
    
    override func prepareForReuse() {
        // memo: Method of super class not necessary to be called, because nothing is proccesed in super class. But you'd better call it?
        super.prepareForReuse()
    }
    
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        // for custom attributes
        if (layoutAttributes.isKindOfClass(AirItemCollectionLayoutAttributes.classForCoder())) {
            
        } else {
            
        }
    }
}
