//
//  GameScene.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import SpriteKit
import Foundation

/// view controller に処理を delegate する
protocol GameSceneDelegate: class {
    func frameTouched(_ location: CGPoint)
    func gameSceneTouched(_ location: CGPoint)
    func actionButtonTouched()
    func didPressMenuButton()
    func viewUpdated()
    func addEvent(_ events: [EventListener])
}

/// ゲーム画面
class GameScene: Scene, GameSceneProtocol {
    var gameSceneDelegate: GameSceneDelegate?
    @IBAction func didPressMenuButton(_ sender: AnyObject) {
        self.gameSceneDelegate?.didPressMenuButton()
    }

    // MARK: GameSceneProtocol Properties

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var eventDialog: DialogLabel!
    var map: Map?
    var textBox: Dialog!

    // MARK: ---
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if map == nil { return }
        let location = touches.first!.location(in: self)
        if self.map!.sheet!.isOnFrame(location) {
            self.gameSceneDelegate?.frameTouched(location)
        } else {
            self.gameSceneDelegate?.gameSceneTouched(location)
        }
    }

    func actionButtonTouched(_ sender: UIButton) {
        self.gameSceneDelegate?.actionButtonTouched()
    }

    override func update(_ currentTime: TimeInterval) {
        map?.updateObjectsZPosition()
        self.gameSceneDelegate?.viewUpdated()
    }

    // MARK: GameSceneProtocol Methods

    func movePlayer(_ playerActions: [SKAction], destination: CGPoint, events: [EventListener], screenActions: [SKAction]) {
        self.textBox.hide()
        self.actionButton.isHidden = true

        let player = self.map?.getObjectByName(objectNameTable.PLAYER_NAME)!
        player?.runAction(playerActions, destination: destination, callback: {
            self.gameSceneDelegate?.addEvent(events)
        })

        if screenActions.isEmpty { return }
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.map?.sheet!.runAction(screenActions, callback: {
            UIApplication.shared.endIgnoringInteractionEvents()
            self.map?.updateObjectPlacement(player!)
        })
    }

    func hideAllButtons() {
        self.textBox.hide()
        self.eventDialog.isHidden = true
        self.menuButton.isHidden = true
        actionButton.isHidden = true
    }

    func showOnlyDefaultButtons() {
        self.hideAllButtons()
        self.menuButton.isHidden = false
    }

    // MARK: ---
}

