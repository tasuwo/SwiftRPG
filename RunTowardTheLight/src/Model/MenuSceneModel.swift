//
//  MenuSceneModel.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

protocol MenuSceneModelDelegate {
    func updateMenuScene()
}

class MenuSceneModel: NSObject, UICollectionViewDataSource {
    var delegate: MenuSceneModelDelegate!
    private(set) var selectedContents: JSON? = nil
    let defaultMessage = "...。"
    private(set) var deselectedIndexPath: NSIndexPath? = nil
    private(set) var selectedIndexPath: NSIndexPath? = nil
    private(set) var contents: JSON = [
        [
            "id" : 1,
            "name" : "タイル1",
            "description" : "テスト1用です",
            "image_name" : "kanamono_gake_01.png",
        ], [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ], [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ], [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ], [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ], [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ],
    ]

    func selectItem(indexPath: NSIndexPath) {
        self.deselectedIndexPath = self.selectedIndexPath
        self.selectedIndexPath = indexPath
        self.delegate.updateMenuScene()
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
        cell.imageView.image = UIImage(named: contents[indexPath.row]["image_name"].string!)
        return cell
    }
}