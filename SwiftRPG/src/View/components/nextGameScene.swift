//
//  nextGameScene.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/29.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SpriteKit
import UIKit

class nextGameScene: GameScene {
    required init(size: CGSize, playerCoordiante: TileCoordinate, playerDirection: DIRECTION) {
        super.init(size: size, playerCoordiante: playerCoordiante, playerDirection: playerDirection)
        Bundle.main.loadNibNamed("nextGameScene", owner: self, options: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        if let map = Map(mapName: "sample_map01", frameWidth: self.frame.width, frameHeight: self.frame.height) {
            self.map = map
            self.map!.addSheetTo(self)
        } else {
            return
        }

        let playerInitialPosition = TileCoordinate.getSheetCoordinateFromTileCoordinate(self.playerInitialCoordinate!)
        let player = Object(name: objectNameTable.PLAYER_NAME,
                            imageName: objectNameTable.getImageBy(direction: self.playerInitialDirection!),
                            position: playerInitialPosition,
                            images: objectNameTable.PLAYER_IMAGE_SET)
        player.setCollision()
        self.map!.setObject(player)
        self.startBehaviors()

        self.map?.sheet?.centerOn(point: player.position, frameWidth: self.frame.width, frameHeight: self.frame.height)

        self.gameSceneDelegate?.enableWalking()

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
