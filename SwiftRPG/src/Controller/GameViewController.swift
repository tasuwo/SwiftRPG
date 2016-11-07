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
    private var model: MenuSceneModel!

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
            let scene = GameScene(size: self.view.bounds.size)
            scene.gameSceneDelegate = self

            let view = self.view as! SKView
            view.presentScene(scene)
            self.view = scene.gameView

            self.model = MenuSceneModel()

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
}

extension GameViewController: GameSceneDelegate {
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
        let newScene = MenuScene(size: self.view.bounds.size)
        newScene.menuSceneDelegate = self

        self.model.delegate = newScene
        newScene.model = self.model
        self.model.updateItems()

        //let view: SKView = self.view as! SKView
        //let transition = SKTransition.fadeWithDuration(1)
        //view.presentScene(newScene, transition: transition)
        self.view = newScene.menuView
    }

    func viewUpdated() {
        do {
            try self.eventManager.cyclicEventDispacher.trigger(self, args: nil)
        } catch EventListenerError.IllegalArguementFormat(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.IllegalParamFormat(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.InvalidParam(let string) {
            print(string)
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch EventListenerError.ParamIsNil {
            print("Required param is nil")
            self.eventManager.cyclicEventDispacher.removeAll()
        } catch {
            print("Unexpected error occured")
            self.eventManager.cyclicEventDispacher.removeAll()
        }
    }

    func addEvent(events: [EventListener]) {
        for event in events {
            self.eventManager.add(event)
        }
    }
}

extension GameViewController: MenuSceneDelegate {
    func didPressBackButton() {
        let newScene = GameScene(size: self.view.bounds.size)
        newScene.gameSceneDelegate = self

        //let view: SKView = self.view as! SKView
        //let transition = SKTransition.fadeWithDuration(1)
        //view.presentScene(newScene, transition: transition)
        self.view = newScene.gameView
    }
    
    func didSelectedItem(indexPath: NSIndexPath) {
        self.model.selectItem(indexPath)
    }
}

extension GameViewController: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
                             sourceController source: UIViewController) ->
        UIViewControllerAnimatedTransitioning?
    {
        transition.originFrame = self.view.frame
        transition.presenting = true
        return transition
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}
