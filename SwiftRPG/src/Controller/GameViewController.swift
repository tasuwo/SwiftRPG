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
    var eventObjectIds: Set<MapObjectId>? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.eventManager = EventManager()
        self.eventManager.enableWalking()
    }

    override func initializeScene() {
        let scene = myGameScene(size: self.view.bounds.size, playerCoordiante: TileCoordinate(x:10,y:10), playerDirection: .down)
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

    // TODO: Error handling when adding or removing event listener has failed

    // This function is executed cyclically
    // The role of this function is as following
    //   - Update object's z-index position.
    //     Front objects should render as looking like upper than back objects.
    //   - Check player collision with events.
    //     If the collision was occurred, invoke event.
    //   - Trigger cyclic event listeners.
    func viewUpdated() {
        let skView = self.view as! SKView
        let gameScene = skView.scene as! GameScene
        let map = gameScene.map

        // Update z-index of objects
        map?.updateObjectsZPosition()

        // If player was on the event object, the listeners which has the placed event's
        // id should be in event dispatcher. But if player left from the event object, 
        // the listeners should be removed from dispatcher as soon as possible.
        // To realize above, the placed event's id should be stored in somewhere.
        //
        // - The role of Object class is to store information about self and generate some
        //   components (e.g. animation) for dealing with self by others.
        // - The role of Map class is to store the state of placement of objects and tiles,
        //   and provide methods for manipulating them.
        //
        // I cannot judge this, so this role add to this controller for now.
        if let events_ = map?.getEventsOnPlayerPosition() {
            let events: [EventListener] = events_

            // Update eventObjectIds value
            if self.eventObjectIds == nil {
                self.eventObjectIds = []
                for event in events {
                    self.eventObjectIds?.insert(event.eventObjectId!)
                }
            } else {
                var newIdSets: Set<MapObjectId> = []
                for event in events {
                    newIdSets.insert(event.eventObjectId!)
                }
                let unregisteredIds = newIdSets.subtracting(self.eventObjectIds!)
                for id in unregisteredIds {
                    self.eventObjectIds?.insert(id)
                }
                let removedIds = self.eventObjectIds?.subtracting(newIdSets)
                for id in removedIds! {
                    self.eventManager.remove(id, sender: gameScene)
                    self.eventObjectIds!.remove(id)
                }
            }

            // Invoke events
            for event in events {
                self.eventManager.add(event)
            }
        } else {
            if self.eventObjectIds != nil {
                for id in self.eventObjectIds! {
                    self.eventManager.remove(id, sender: gameScene)
                }
                self.eventObjectIds = nil
            }
        }

        // Trigger cyclic events
        do {
            try self.eventManager.trigger(.immediate, sender: gameScene, args: nil)
        } catch EventManagerError.FailedToTrigger(let string) {
            print("Failed to trigger cyclic event: " + string)
        } catch {
            print("Unexpected error has occurred during triggering cyclic event")
        }
    }

    func startBehaviors(_ behaviors: Dictionary<MapObjectId, EventListener>) {
        if self.eventManager.isBlockingBehavior == false { return }
        self.eventManager.unblockBehavior()
        for behavior in behaviors.values {
            behavior.isExecuting = false
            self.eventManager.add(behavior)
        }
    }

    func stopBehaviors() {
        self.eventManager.blockBehavior()
    }

    func enableWalking() {
        self.eventManager.enableWalking()
    }

    func disableWalking() {
        self.eventManager.disableWalking()
    }
}
