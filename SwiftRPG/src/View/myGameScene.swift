//
//  myGameScene.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class myGameScene: GameScene {
    override init(size: CGSize) {
        super.init(size: size)
        Bundle.main.loadNibNamed("myGameScene", owner: self, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        /* 地形の読み込み */
        if let map = Map(mapName: "sample_map02", frameWidth: self.frame.width, frameHeight: self.frame.height) {
            self.map = map
            self.map!.addSheetTo(self)
        }

        // 主人公の作成
        let player = Object(name: objectNameTable.PLAYER_NAME,
                            imageName: objectNameTable.PLAYER_IMAGE_DOWN,
                            position: TileCoordinate.getSheetCoordinateFromTileCoordinate(TileCoordinate(x: 10, y: 10)),
                            images: objectNameTable.PLAYER_IMAGE_SET)
        self.map!.setObject(player)

        actionButton.layer.borderColor = UIColor.white.cgColor
        actionButton.addTarget(self, action: #selector(GameScene.actionButtonTouched(_:)), for: .touchUpInside)
        actionButton.isHidden = true

        textBox = Dialog(frame_width: self.frame.width, frame_height: self.frame.height)
        textBox.hide()
        textBox.setPositionY(Dialog.POSITION.top)
        textBox.addTo(self)

        eventDialog.isHidden = true
        eventDialog.layer.backgroundColor = UIColor.black.cgColor
        eventDialog.layer.borderColor = UIColor.white.cgColor
        
        menuButton.layer.borderColor = UIColor.white.cgColor
    }
}
