//
//  AirItemCollectionViewLayout.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/10.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

// memo: Storyboardではなく、collectionView.setCollectionViewLayoutで設定
// UICollectionViewControllerを継承した場合、FlowLayoutが設定されるので、UIViewControllerを継承し、CollectionViewを追加
// Register decoratin view class if necessary
// ジェスチャーを追加する場合、CollectionViewで検知された位置情報などをLayoutに通知し、LayoutのlayoutAttributesXXXで
// 更新後のattributesを返す。位置情報によって、対象cellの計算する必要がある。
// デフォルトでtap/longtapのジェスチャーが登録されているので、UIGestrureRecognizerのrequireGestureRecognizerToFailを読んでから登録する必要がある
class AirItemCollectionViewLayout: UICollectionViewLayout {
   
    // e.g. size and position of each item(cell, supplementary, decoration)
    override func prepareLayout() {
        // todo: calculate
        
    }
    
    // whole size for content
    override func collectionViewContentSize() -> CGSize {
        // todo: return content size that calulated in prepareLayout
        return CGSizeZero
    }
    
    // attributes for displying
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: [UICollectionViewLayoutAttributes]?
        
        // todo: check if elements in rect.(get attributes e.g. frame of element from layoutAttributexForxxx method, and check with rect. Add to array if intersect with rect.) 
        // item
        // supplementary view
        // decoration view
        
        // attributes updated
        return attributesArray
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes: AirItemCollectionLayoutAttributes = super.layoutAttributesForItemAtIndexPath(indexPath) as! AirItemCollectionLayoutAttributes
        
        // update attributes
        
        return attributes
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes: AirItemCollectionLayoutAttributes = super.layoutAttributesForSupplementaryViewOfKind(elementKind, atIndexPath: indexPath) as! AirItemCollectionLayoutAttributes
        
        // update attributes with kind
        
        return attributes
    }
    
    override func layoutAttributesForDecorationViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        var attributes: AirItemCollectionLayoutAttributes = super.layoutAttributesForDecorationViewOfKind(elementKind, atIndexPath: indexPath) as! AirItemCollectionLayoutAttributes
        
        // update attributes with kind that defined in decoration view
        
        return attributes
    }
    
    
    // animation for inserting, moving and deleting
    
    // index path inserted/deleted/moved
    override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
        //super.prepareForCollectionViewUpdates(updateItems)
        
        for obj: AnyObject in updateItems {
            let updateItem: UICollectionViewUpdateItem = obj as! UICollectionViewUpdateItem
            
            if (updateItem.updateAction == UICollectionUpdateAction.Insert) {
                // save insert indexPath with updateItem.indexPathAfterUpdate
            } else if (updateItem.updateAction == UICollectionUpdateAction.Move) {
                
            } else if (updateItem.updateAction == UICollectionUpdateAction.Delete) {
                // save delete indexPath with updateItem.indexPathBeforeUpdate
            }
        }
    }
    
    // for inserting items
    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        // set final attributes for displaying on the screen(saved index path for inserting items)
        // set AirItemxxxAttributes and return
        var attributes: AirItemCollectionLayoutAttributes?
        
        // nothing to change attributes for other items
        //return super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)
        return attributes
    }
    
    // for deleting items
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        // set final attributes for displaying on the screen(saved index path for deleting items)
        // set AirItemxxxAttributes and return
        var attributes: AirItemCollectionLayoutAttributes?
        
        // nothing to change attributes for other items
        //return super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
        return attributes
    }
    
    override func finalizeCollectionViewUpdates() {
        //super.finalizeCollectionViewUpdates()
        
        // clear index path of items saved
    }
}
