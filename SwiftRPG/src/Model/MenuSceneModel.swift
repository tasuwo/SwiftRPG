//
//  MenuSceneModel.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import RealmSwift

protocol MenuSceneModelDelegate {
    func updateItemSelect()
    func reloadTable()
}

class MenuSceneModel: NSObject, UICollectionViewDataSource {
    var delegate: MenuSceneModelDelegate!
    private(set) var selectedContents: JSON? = nil
    let defaultMessage = "...。"
    private(set) var deselectedIndexPath: NSIndexPath? = nil
    private(set) var selectedIndexPath: NSIndexPath? = nil
    private(set) var contents: [Item] = []

    func updateItems() {
        let realm = try! Realm()
        let items = realm.objects(StoredItems)
        for item in items {
            contents.append(Item(key: item.key, name: item.name, description: item.text, image_name: item.image_name))
        }
        self.delegate.reloadTable()
    }

    func selectItem(indexPath: NSIndexPath) {
        self.deselectedIndexPath = self.selectedIndexPath
        self.selectedIndexPath = indexPath
        self.delegate.updateItemSelect()
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contents.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ItemCell
        cell.imageView.image = UIImage(named: contents[indexPath.row].image_name)
        return cell
    }
}