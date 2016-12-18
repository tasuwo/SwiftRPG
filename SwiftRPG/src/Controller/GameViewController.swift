//
//  GameViewController.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import SwiftyJSON

class GameViewController: UIViewController {
    var viewInitiated: Bool = false
    var eventManager: EventManager!
    let transition = TransitionBetweenGameAndMenuSceneAnimator()
    fileprivate var model: MenuSceneModel!

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

            self.model = MenuSceneModel()

            self.viewInitiated = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return UIInterfaceOrientationMask.allButUpsideDown
        } else {
            return UIInterfaceOrientationMask.all
        }
    }
}

extension GameViewController: GameSceneDelegate {
    func frameTouched(_ location: CGPoint) {}

    func gameSceneTouched(_ location: CGPoint) {
        let args = JSON(["touchedPoint": NSStringFromCGPoint(location)])
        do {
            try self.eventManager.touchEventDispacher.trigger(self, args: args)
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
            try self.eventManager.actionButtonEventDispacher.trigger(self, args: nil)
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
        let newScene = MenuScene(size: self.view.bounds.size)
        newScene.menuSceneDelegate = self

        self.model.delegate = newScene
        newScene.model = self.model
        self.model.updateItems()

        self.view = newScene.menuView
        let view: SKView = self.view as! SKView
        view.presentScene(newScene)
    }

    func viewUpdated() {
        do {
            try self.eventManager.cyclicEventDispacher.trigger(self, args: nil)
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

extension GameViewController: MenuSceneDelegate {
    func didPressBackButton() {
        let newScene = GameScene(size: self.view.bounds.size)
        newScene.gameSceneDelegate = self

        self.view = newScene.gameView
        let view: SKView = self.view as! SKView
        view.presentScene(newScene)
    }
    
    func didSelectedItem(_ indexPath: IndexPath) {
        self.model.selectItem(indexPath)
    }
}

extension GameViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
                             source: UIViewController) ->
        UIViewControllerAnimatedTransitioning?
    {
        transition.originFrame = self.view.frame
        transition.presenting = true
        return transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}
