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

class GameViewController: UIViewController {
    var viewInitiated: Bool = false
    var eventManager: EventManager!

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isMultipleTouchEnabled = false

        self.eventManager = EventManager()
        eventManager.add(WalkEventListener(params: nil, chainListeners: nil))
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if (!viewInitiated) {
            let scene = GameScene(size: self.view.bounds.size)
            scene.gameSceneDelegate = self

            self.view = scene.gameView
            let view = self.view as! SKView
            view.presentScene(scene)

            self.viewInitiated = true
        }
    }
}

extension GameViewController: GameSceneDelegate {
    func frameTouched(_ location: CGPoint) {}

    func gameSceneTouched(_ location: CGPoint) {
        let args = JSON(["touchedPoint": NSStringFromCGPoint(location)])
        do {
            let skView = self.view as! SKView
            let gameScene = skView.scene as! GameScene
            try self.eventManager.touchEventDispacher.trigger(gameScene, args: args)
        } catch EventListenerError.illegalArguementFormat(let string) {
            print(string)
        } catch EventListenerError.illegalParamFormat(let string) {
            print(string)
        } catch EventListenerError.invalidParam(let string) {
            print(string)
        } catch EventListenerError.paramIsNil {
            print("Required param is nil")
        } catch {
            print("Unexpected error occured")
        }
    }

    func actionButtonTouched() {
        do {
            let skView = self.view as! SKView
            let gameScene = skView.scene as! GameScene
            try self.eventManager.actionButtonEventDispacher.trigger(gameScene, args: nil)
        } catch EventListenerError.illegalArguementFormat(let string) {
            print(string)
        } catch EventListenerError.illegalParamFormat(let string) {
            print(string)
        } catch EventListenerError.invalidParam(let string) {
            print(string)
        } catch EventListenerError.paramIsNil {
            print("Required param is nil")
        } catch {
            print("Unexpected error occured")
        }
    }

    func didPressMenuButton() {
        let viewController = MenuViewController()
        self.present(viewController, animated: true, completion: nil)
    }

    func viewUpdated() {
        do {
            let skView = self.view as! SKView
            let gameScene = skView.scene as! GameScene
            try self.eventManager.cyclicEventDispacher.trigger(gameScene, args: nil)
        } catch EventListenerError.illegalArguementFormat(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.illegalParamFormat(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.invalidParam(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.paramIsNil {
            print("Required param is nil")
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch {
            print("Unexpected error occured")
            self.eventManager.cyclicEventDispacher.removeAll()
        }
    }

    func addEvent(_ events: [EventListener]) {
        for event in events {
            self.eventManager.add(event)
        }
    }
}
