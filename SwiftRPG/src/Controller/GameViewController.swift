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
import SwiftyJSON

/// ゲーム画面の view controller
class GameViewController: UIViewController, GameSceneDelegate {
    var viewInitiated: Bool = false
    var eventManager: EventManager!

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.multipleTouchEnabled = false

        self.eventManager = EventManager()
        eventManager.add(WalkEventListener(params: nil, chainListeners: nil))
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

    func frameTouched(location: CGPoint) {}

    func gameSceneTouched(location: CGPoint) {
        let args = JSON(["touchedPoint": NSStringFromCGPoint(location)])
        do {
            try self.eventManager.touchEventDispacher.trigger(self, args: args)
        } catch EventListenerError.IllegalArguementFormat(let string) {
            print(string)
        } catch EventListenerError.IllegalParamFormat(let string) {
            print(string)
        } catch EventListenerError.InvalidParam(let string) {
            print(string)
        } catch EventListenerError.ParamIsNil {
            print("Required param is nil")
        } catch {
            print("Unexpected error occured")
        }
    }

    func actionButtonTouched() {
        do {
            try self.eventManager.actionButtonEventDispacher.trigger(self, args: nil)
        } catch EventListenerError.IllegalArguementFormat(let string) {
            print(string)
        } catch EventListenerError.IllegalParamFormat(let string) {
            print(string)
        } catch EventListenerError.InvalidParam(let string) {
            print(string)
        } catch EventListenerError.ParamIsNil {
            print("Required param is nil")
        } catch {
            print("Unexpected error occured")
        }
    }

    func didPressMenuButton() {
        let menuViewController: UIViewController = MenuViewController()
        self.presentViewController(menuViewController, animated: false, completion: nil)
    }

    func viewUpdated() {
        do {
            try self.eventManager.cyclicEventDispacher.trigger(self, args: nil)
        } catch EventListenerError.IllegalArguementFormat(let string) {
            print(string)
        } catch EventListenerError.IllegalParamFormat(let string) {
            print(string)
        } catch EventListenerError.InvalidParam(let string) {
            print(string)
        } catch EventListenerError.ParamIsNil {
            print("Required param is nil")
        } catch {
            print("Unexpected error occured")
        }
    }

    func addEvent(events: [EventListener]) {
        for event in events {
            self.eventManager.add(event)
        }
    }
}
