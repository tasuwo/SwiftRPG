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
            try self.eventManager.trigger(.touch, sender: gameScene, args: args)
        } catch EventManagerError.FailedToTrigger(let string) {
            print("Failed to trigger touch event: " + string)
        } catch {
            print("Unexpected error has occurred during triggering touch event")
        }
    }

    func actionButtonTouched() {
        let skView = self.view as! SKView
        let gameScene = skView.scene as! GameScene

        do {
            try self.eventManager.trigger(.button, sender: gameScene, args: nil)
        } catch EventManagerError.FailedToTrigger(let string) {
            print("Failed to trigger action event: " + string)
        } catch {
            print("Unexpected error has occurred during triggering action event")
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
            try self.eventManager.trigger(.immediate, sender: gameScene, args: nil)
        } catch EventManagerError.FailedToTrigger(let string) {
            print("Failed to trigger cyclic event: " + string)
        } catch {
            print("Unexpected error has occurred during triggering cyclic event")

            // If cyclic event couldn't execute, the game might be hang
            // So when error has occurred, remove all cyclic events
            // TODO: Remove only cyclic event which is cause of exception
            self.eventManager.removeAllEvents(.immediate)
        }
    }

    func addEvent(_ events: [EventListener]) {
        for event in events {
            if self.eventManager.add(event) == false {
                // TODO: Deal with failure
                print("Failed to adding event")
            }
        }
    }

    func registerBehaviors(_ behaviors: Dictionary<MapObjectId, EventListener>) {
        for behavior in behaviors.values {
            if self.eventManager.add(behavior) == false {
                // TODO: Deal with failure
                print("Failed to adding event")
            }
        }
    }
}
