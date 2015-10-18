//
//  AirItemCollectionViewFlowLayout.swift
//  AirCommCamera
//
//  Created by 文光石 on 2015/09/10.
//  Copyright (c) 2015年 Threees. All rights reserved.
//

import UIKit

// memo: Call super.method when override method of super for subclass of xxxFlowLayout
class AirItemCollectionViewFlowLayout: UICollectionViewFlowLayout {
   
    // e.g. size and position of each item
    //override func prepareLayout() {
    //    super.prepareLayout()
    //}
    
    // whole size for content
    //override func collectionViewContentSize() -> CGSize {
    //    return super.collectionViewContentSize()
    //}
    
    // attributes for displying
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // memo: Recturn elements attributes that intersect with rect from super class.
        var attributesArray: [UICollectionViewLayoutAttributes]? = super.layoutAttributesForElementsInRect(rect)
        
        for obj: AnyObject in attributesArray! {
            var attributes: AirItemCollectionLayoutAttributes = obj as! AirItemCollectionLayoutAttributes
            
            // update attributes for xxx
            if (attributes.representedElementCategory == UICollectionElementCategory.Cell) {
                
            } else if (attributes.representedElementCategory == UICollectionElementCategory.SupplementaryView) {
                
            } else if (attributes.representedElementCategory == UICollectionElementCategory.DecorationView) {
                
            }
        }
        
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
        
        // update attributes with kind
        
        return attributes
    }
    
    
    // animation for inserting, moving and deleting
    
    // index path inserted/deleted/moved
    override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
        super.prepareForCollectionViewUpdates(updateItems)
        
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
        
        // nothing to change attributes for other items
        return super.initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath)
    }
    
    // for deleting items
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        // set final attributes for displaying on the screen(saved index path for deleting items)
        // set AirItemxxxAttributes and return
        
        // nothing to change attributes for other items
        return super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
    }
    
    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        
        // clear index path of items saved
    }
    
    // layout when orientation changed.
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
}
