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
class GameScene: SKScene, GameSceneProtocol {
    var gameSceneDelegate: GameSceneDelegate?

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var eventDialog: DialogLabel!
    @IBOutlet var gameView: SKView!
    @IBAction func didPressMenuButton(_ sender: AnyObject) {
        self.gameSceneDelegate?.didPressMenuButton()
    }

    /* ゲーム画面の各構成要素 */
    var map: Map?
    var textBox: Dialog!

    override init(size: CGSize) {
        super.init(size: size)
        Bundle.main.loadNibNamed("GameScene", owner: self, options: nil)
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

    // MARK: EventListener

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
}

