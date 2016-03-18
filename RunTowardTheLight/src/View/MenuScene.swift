//
//  MenuScene.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

protocol MenuSceneDelegate {
    func didPressBackButton()
}

class MenuScene: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    var menuSceneDelegate: MenuSceneDelegate?
    
    var contents: [String] = [
        "kanamono_gake_01.png",
        "kanamono_gake_02.png"
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
        
        // DEBUG:
        imageView.image = UIImage(named: "title.png")
        
        dialog.layer.borderColor = UIColor.whiteColor().CGColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        cell.imageView.image = UIImage(named: contents[indexPath.row])
        return cell
    }
}