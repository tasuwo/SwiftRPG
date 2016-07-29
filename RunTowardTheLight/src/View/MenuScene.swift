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
    func didSelectedItem(indexPath: NSIndexPath)
}

class MenuScene: UIView, UICollectionViewDelegate, MenuSceneModelDelegate {
    var menuSceneDelegate: MenuSceneDelegate?
    var model: MenuSceneModel! {
        didSet {
            self.contentsView.dataSource = self.model
            self.dialog.text = self.model!.defaultMessage
        }
    }
    private static let SELECTED_ALPHA: CGFloat = 1.0
    private static let DESELECTED_ALPHA: CGFloat = 0.5
    
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
        contentsView.registerClass(ItemCell.self, forCellWithReuseIdentifier: "cell")
        
        // DEBUG:
        imageView.image = UIImage(named: "title.png")

        dialog.layer.borderColor = UIColor.whiteColor().CGColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: MenuSceneModelDelegate

    func updateMenuScene() {
        let selectedCell = self.contentsView.cellForItemAtIndexPath(self.model.selectedIndexPath!) as! ItemCell

        // 選択されたセル以外の全てのセルを非選択にする
        for cell in self.contentsView.visibleCells() as! [ItemCell] {
            if cell == selectedCell { continue }
            cell.imageView.alpha = MenuScene.DESELECTED_ALPHA
        }

        // 選択されたセルとテキストボックスの描画更新
        if selectedCell.imageView.alpha == MenuScene.SELECTED_ALPHA {
            selectedCell.imageView.alpha = MenuScene.DESELECTED_ALPHA
            self.dialog.text = self.model.defaultMessage
        } else {
            selectedCell.imageView.alpha = MenuScene.SELECTED_ALPHA
            self.dialog.text = self.model.contents[self.model.selectedIndexPath!.row]["description"].string!
        }
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.menuSceneDelegate?.didSelectedItem(indexPath)
    }
}