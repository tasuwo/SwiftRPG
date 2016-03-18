//
//  MenuScene.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

protocol MenuSceneDelegate {
    func didPressBackButton()
}

class MenuScene: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    var menuSceneDelegate: MenuSceneDelegate?
    
    var selectedContents: JSON? = nil
    
    var defaultMessage: String = "...。"
    
    var contents: JSON = [
        [
            "id" : 1,
            "name" : "タイル1",
            "description" : "テスト1用です",
            "image_name" : "kanamono_gake_01.png",
        ],
        [
            "id" : 2,
            "name" : "タイル2",
            "description" : "テスト2用です",
            "image_name" : "kanamono_gake_01.png",
        ],
    ]
    
    @IBOutlet var menuView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var menuListView: UIView!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var dialog: UILabel!
    
    @IBOutlet weak var contentsView: UICollectionView!
    
    @IBAction func showPreviousContents(sender: AnyObject) {
    }
    
    @IBAction func showNextContents(sender: AnyObject) {
    }
    
    @IBAction func didPressBackButton(sender: AnyObject) {
        self.menuSceneDelegate?.didPressBackButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NSBundle.mainBundle().loadNibNamed("MenuScene", owner: self, options: nil)
        menuView.frame = frame
        addSubview(menuView)
        
        contentsView.delegate = self
        contentsView.dataSource = self
        contentsView.registerClass(ItemCell.self, forCellWithReuseIdentifier: "cell")
        
        dialog.text = defaultMessage
        
        // DEBUG:
        imageView.image = UIImage(named: "title.png")
        
        dialog.layer.borderColor = UIColor.whiteColor().CGColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // 選択状態の初期化
        self.selectedContents = nil
        for var i=0; i<self.contentsView.numberOfSections(); i++ {
            for var j=0; j<self.contentsView.numberOfItemsInSection(i); j++ {
                if j != indexPath.row {
                    let cell = self.contentsView.cellForItemAtIndexPath(NSIndexPath(forRow: j, inSection: i)) as! ItemCell
                    cell.imageView.alpha = 0.5
                }
            }
        }
        
        let selectedCell: ItemCell = self.contentsView.cellForItemAtIndexPath(indexPath) as! ItemCell
        
        // セルが選択済みであれば選択解除
        if selectedCell.imageView.alpha == 1.0 {
            selectedCell.imageView.alpha = 0.5
            self.dialog.text = defaultMessage
            return
        }
        
        selectedCell.imageView.alpha = 1.0
        self.dialog.text = self.contents[indexPath.row]["description"].string!
        self.selectedContents = self.contents[indexPath.row]
    }
    
    // MARK : UICollectionViewDelegate
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // MARK : UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.contents.count
    }

    // MARK : UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! ItemCell
        cell.imageView.image = UIImage(named: contents[indexPath.row]["image_name"].string!)
        return cell
    }
}