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

class GameViewController: UIViewController, GameSceneDelegate {
    var viewInitiated: Bool = false
    var movePlayer_: EventListener<CGPoint>!
    var touchEvent = EventDispatcher<CGPoint>()
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
            let scene = GameScene(size: self.view.bounds.size)
            scene.gameSceneDelegate = self

            let skView = self.view as! SKView
            skView.presentScene(scene)

            self.viewInitiated = true
        }
    }

    func displayTouched(touch: UITouch?) {
        let skView = self.view as! SKView
        let location = touch?.locationInNode(skView.scene!)
        touchEvent.trigger(self, args: location)
    }

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
