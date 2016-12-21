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
    func didSelectedItem(_ indexPath: IndexPath)
}

class MenuScene: Scene {
    var menuSceneDelegate: MenuSceneDelegate?
    var model: MenuSceneModel! {
        didSet {
            self.contentsView.dataSource = self.model
            self.dialog.text = self.model!.defaultMessage
        }
    }
    fileprivate static let SELECTED_ALPHA: CGFloat = 1.0
    fileprivate static let DESELECTED_ALPHA: CGFloat = 0.5
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var dialog: UILabel!
    @IBOutlet weak var contentsView: UICollectionView!
    @IBAction func didPressBackButton(_ sender: AnyObject) {
        self.menuSceneDelegate?.didPressBackButton()
    }
    
    override init(size: CGSize) {
        super.init(size: size)

        Bundle.main.loadNibNamed("MenuScene", owner: self, options: nil)
        self.view?.addSubview(sceneView)

        contentsView.delegate = self
        contentsView.register(ItemCell.self, forCellWithReuseIdentifier: "cell")
        
        dialog.layer.borderColor = UIColor.white.cgColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MenuScene: MenuSceneModelDelegate {
    func updateItemSelect() {
        let selectedCell = self.contentsView.cellForItem(at: self.model.selectedIndexPath!) as! ItemCell

        // 選択されたセル以外の全てのセルを非選択にする
        for cell in self.contentsView.visibleCells as! [ItemCell] {
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
}

extension MenuScene: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.menuSceneDelegate?.didSelectedItem(indexPath)
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 40)
    }
}
