//
//  GameViewController.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import SwiftyJSON

class GameViewController: SceneController {
    var eventManager: EventManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.eventManager = EventManager()
        // TODO: 追加失敗時の処理
        if eventManager.add(WalkEventListener(params: nil, chainListeners: nil)) == false {}
    }

    override func initializeScene() {
        let scene = myGameScene(size: self.view.bounds.size)
        scene.gameSceneDelegate = self
        self.scene = scene
    }
}

extension GameViewController: GameSceneDelegate {
    func frameTouched(_ location: CGPoint) {}

    func gameSceneTouched(_ location: CGPoint) {
        let args = JSON(["touchedPoint": NSStringFromCGPoint(location)])
        let skView = self.view as! SKView
        let gameScene = skView.scene as! GameScene

        do {
            try self.eventManager.touchEventDispacher.trigger(gameScene, args: args)
        } catch {
            print("Unexpected error occured")
        }
    }

    func actionButtonTouched() {
        let skView = self.view as! SKView
        let gameScene = skView.scene as! GameScene

        do {
            try self.eventManager.actionButtonEventDispacher.trigger(gameScene, args: nil)
        } catch {
            print("Unexpected error occured")
        }
    }

    func menuButtonTouched() {
        let viewController = MenuViewController()
        self.present(viewController, animated: true, completion: nil)
    }

    func viewUpdated() {
        let skView = self.view as! SKView
        let gameScene = skView.scene as! GameScene

        do {
            try self.eventManager.cyclicEventDispacher.trigger(gameScene, args: nil)
        } catch {
            print("Unexpected error occured")
            self.eventManager.cyclicEventDispacher.removeAll()
        }
    }

    func addEvent(_ events: [EventListener]) {
        for event in events {
            // TODO: 追加失敗時の処理
            if self.eventManager.add(event) == false {
                return
            }
        }
    }

    func registerBehaviors(_ behaviors: Dictionary<MapObjectId, EventListener>) {
        for behavior in behaviors.values {
            if self.eventManager.add(behavior) == false {
                // TODO: 追加失敗時の処理
                return
            }
        }
    }
}
