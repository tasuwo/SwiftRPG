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
    var viewInitiated: Bool = false
    
    /// プレイヤー移動用のイベント
    var movePlayer_: EventListener<CGPoint>!
    
    /*  ユーザの操作によって呼び出される処理を保持するイベント */
    /// タッチ時のイベント
    var touchEvent = EventDispatcher<CGPoint>()
    /// ボタン押下時のイベント
    var actionEvent = EventDispatcher<AnyObject?>()

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.multipleTouchEnabled = false

        movePlayer_ = GameSceneEvent.touchEvents["common_moving"]!(nil)
        touchEvent.add(movePlayer_)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if (!viewInitiated) {
            // 1. delegate を設定した game scene を生成
            let scene = GameScene(size: self.view.bounds.size)
            scene.gameSceneDelegate = self

            // 2. game scene を親とした skview 生成
            let skView = self.view as! SKView
            skView.presentScene(scene)

            self.viewInitiated = true
        }
    }

    ///  ディスプレイがタッチされた際に呼ばれる
    ///  タッチ位置をタッチイベントに渡す
    ///
    ///  - parameter touch: タッチの情報
    func displayTouched(touch: UITouch?) {
        let skView = self.view as! SKView
        let location = touch?.locationInNode(skView.scene!)
        touchEvent.trigger(self, args: location)
    }

    ///  画面上のアクションボタン押下時に呼ばれる
    func actionButtonTouched() {
        actionEvent.trigger(self, args: nil)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}
