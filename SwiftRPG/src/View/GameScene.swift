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
    func frameTouched(location: CGPoint)
    func gameSceneTouched(location: CGPoint)
    func actionButtonTouched()
    func didPressMenuButton()
    func viewUpdated()
    func addEvent(events: [EventListener])
}

/// ゲーム画面
class GameScene: SKScene {
    var gameSceneDelegate: GameSceneDelegate?

    @IBOutlet var gameView: SKView!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBAction func didPressMenuButton(sender: AnyObject) {
        self.gameSceneDelegate?.didPressMenuButton()
    }
    @IBOutlet weak var eventDialog: DialogLabel!

    /* ゲーム画面の各構成要素 */
    var map: Map?
    var textBox_: Dialog!
    var actionButton_: UIButton!

    override init(size: CGSize) {
        super.init(size: size)
        NSBundle.mainBundle().loadNibNamed("GameScene", owner: self, options: nil)
        gameView.presentScene(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToView(view: SKView) {
        if let map = Map(mapName: "sample_map02", frameWidth: self.frame.width, frameHeight: self.frame.height) {
            self.map = map
            self.map!.addSheetTo(self)
        }

        actionButton.layer.borderColor = UIColor.whiteColor().CGColor
        actionButton.addTarget(self, action: #selector(GameScene.actionButtonTouched(_:)), forControlEvents: .TouchUpInside)
        actionButton.hidden = true

        menuButton.layer.borderColor = UIColor.whiteColor().CGColor

        textBox_ = Dialog(frame_width: self.frame.width, frame_height: self.frame.height)
        textBox_.hide()
        textBox_.setPositionY(Dialog.POSITION.top)
        textBox_.addTo(self)

        eventDialog.hidden = true
        eventDialog.layer.backgroundColor = UIColor.blackColor().CGColor
        eventDialog.layer.borderColor = UIColor.whiteColor().CGColor
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if map == nil { return }
        let location = touches.first!.locationInNode(self)
        if self.map!.sheet!.isOnFrame(location) {
            self.gameSceneDelegate?.frameTouched(location)
        } else {
            self.gameSceneDelegate?.gameSceneTouched(location)
        }
    }

    func actionButtonTouched(sender: UIButton) {
        self.gameSceneDelegate?.actionButtonTouched()
    }

    override func update(currentTime: CFTimeInterval) {
        map?.updateObjectsZPosition()
        self.gameSceneDelegate?.viewUpdated()
    }

    // MARK: EventListener

    func movePlayer(playerActions: [SKAction], destination: CGPoint, events: [EventListener], screenActions: [SKAction]) {
        self.textBox_.hide()
        self.actionButton.hidden = true

        let player = self.map?.getObjectByName(objectNameTable.PLAYER_NAME)!
        player?.runAction(playerActions, destination: destination, callback: {
            self.gameSceneDelegate?.addEvent(events)
        })

        if screenActions.isEmpty { return }
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        self.map?.sheet!.runAction(screenActions, callback: {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            self.map?.updateObjectPlacement(player!)
        })
    }
}