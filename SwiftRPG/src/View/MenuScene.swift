//
//  MenuScene.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import SpriteKit

protocol MenuSceneDelegate {
    func didPressBackButton()
    func didSelectedItem(indexPath: NSIndexPath)
}

class MenuScene: SKScene, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MenuSceneModelDelegate {
    var menuSceneDelegate: MenuSceneDelegate?
    var model: MenuSceneModel! {
        didSet {
            self.contentsView.dataSource = self.model
            self.dialog.text = self.model!.defaultMessage
        }
    }
    private static let SELECTED_ALPHA: CGFloat = 1.0
    private static let DESELECTED_ALPHA: CGFloat = 0.5
    
    @IBOutlet var menuView: SKView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var menuListView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var dialog: UILabel!
    @IBOutlet weak var contentsView: UICollectionView!
    @IBAction func didPressBackButton(sender: AnyObject) {
        self.menuSceneDelegate?.didPressBackButton()
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        NSBundle.mainBundle().loadNibNamed("MenuScene", owner: self, options: nil)
        self.view?.addSubview(menuView)

        contentsView.delegate = self
        contentsView.registerClass(ItemCell.self, forCellWithReuseIdentifier: "cell")
        
        // DEBUG:
        imageView.backgroundColor = UIColor.whiteColor()

        dialog.layer.borderColor = UIColor.whiteColor().CGColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: MenuSceneModelDelegate

    func updateItemSelect() {
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
            self.dialog.text = self.model.contents[self.model.selectedIndexPath!.row].description
        }
    }

    func reloadTable() {
        self.contentsView.reloadData()
    }

    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.menuSceneDelegate?.didSelectedItem(indexPath)
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(40, 40)
    }
}