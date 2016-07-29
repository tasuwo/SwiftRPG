//
//  GameViewController.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

/// ゲーム画面の view controller
class GameViewController: UIViewController, GameSceneDelegate {
    /// ビューの初期化フラグ
    var viewInitiated: Bool = false
    
    /// プレイヤー移動用のイベント
    var movePlayer_: EventListener<Any>!
    
    /// タッチ時のイベント
    var touchEvent = EventDispatcher<Any>()
    
    /// ボタン押下時のイベント
    var actionEvent = EventDispatcher<Any>()
    
    
    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.multipleTouchEnabled = false

        movePlayer_ = GameSceneEvent.events[GameSceneEvent.PLAYER_MOVE]!(nil)
        touchEvent.removeAll()
        touchEvent.add(movePlayer_)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if (!viewInitiated) {
            // 1. delegate を設定した game scene を生成
            let scene = GameScene(size: self.view.bounds.size)
            scene.gameSceneDelegate = self

            // 2. game scene を親とした skview 取得
            self.view = scene.gameView

            self.viewInitiated = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    // MARK: GameSceneDelegate
    
    func displayTouched(touch: UITouch?) {
        let skView = self.view as! SKView
        let location = touch?.locationInNode(skView.scene!)
        touchEvent.trigger(self, args: location)
    }

    func actionButtonTouched() {
        actionEvent.trigger(self, args: nil)
    }
    
    func didPressMenuButton() {
        let menuViewController: UIViewController = MenuViewController()
        self.presentViewController(menuViewController, animated: false, completion: nil)
    }
    
    func sceneUpdated() {}
}
