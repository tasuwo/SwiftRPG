//
//  GameScene.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import SpriteKit
import Foundation

/// view controller に処理を delegate する
protocol GameSceneDelegate: class {
    func displayTouched(touch: UITouch?)
    func actionButtonTouched()
    func didPressMenuButton()
    func sceneUpdated()
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
    
    /* ゲーム画面の各構成要素 */
    var map: Map!
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
        // マップ生成
        if let map = Map(mapName: "sample_map02", frameWidth: self.frame.width, frameHeight: self.frame.height) {
            self.map = map
            self.map.addSheetTo(self)
        }
        
        actionButton.layer.borderColor = UIColor.whiteColor().CGColor
        actionButton.addTarget(self, action: #selector(GameScene.actionButtonTouched(_:)), forControlEvents: .TouchUpInside)
        actionButton.hidden = true
        
        menuButton.layer.borderColor = UIColor.whiteColor().CGColor

        textBox_ = Dialog(frame_width: self.frame.width, frame_height: self.frame.height)
        textBox_.hide()
        textBox_.setPositionY(Dialog.POSITION.top)
        textBox_.addTo(self)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // コントローラに処理を委譲する
        self.gameSceneDelegate?.displayTouched(touches.first)
    }

    func actionButtonTouched(sender: UIButton) {
        self.gameSceneDelegate?.actionButtonTouched()
    }
    
    override func update(currentTime: CFTimeInterval) {
        self.gameSceneDelegate?.sceneUpdated()
        map.updateObjectsZPosition()
    }
}