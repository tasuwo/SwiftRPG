//
//  MoveObjectEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/23.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON
import JSONSchema
import PromiseKit

class MoveObjectEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "direction": ["type":"string"],
                "step_num": ["type":"string"],
                "speed": ["type":"string"]
            ],
            "required": ["name", "direction", "step_num", "speed"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.params = params
        self.listeners = chainListeners
        self.triggerType = .immediate
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) in
            self.isExecuting = true
            let map   = sender!.map!

            let objectName = self.params?["name"].string!
            let direction_str = self.params?["direction"].string!
            let direction = DIRECTION.fromString(direction_str!)
            let step_num = Int((self.params?["step_num"].string!)!)
            let speed = Int((self.params?["speed"].string!)!)

            let object = map.getObjectByName(objectName!)!
            object.setDirection(direction!)
            object.setSpeed(CGFloat(speed!))

            // Disable events
            // Remove all events related to object from map
            let eventObjectIds = object.getChildrenIds()
            for id in eventObjectIds {
                map.removeObject(id)
            }

            let departure = object.coordinate
            let destination = self.calcDestination(departure, direction: direction!, step_num: step_num!)

            // Route search by A* algorithm
            let aStar = AStar(map: map)
            aStar.initialize(departure, destination: destination)
            let path = aStar.main()
            if path == nil { return }

            // Define action for moving
            var objectActions: Array<SKAction> = []
            var preStepCoordinate = object.coordinate
            var preStepPoint = object.position
            for nextStepCoordinate: TileCoordinate in path! {
                let nextStepPoint: CGPoint = TileCoordinate.getSheetCoordinateFromTileCoordinate(nextStepCoordinate)
                objectActions += object.getActionTo(
                    preStepPoint,
                    destination: nextStepPoint,
                    preCallback: {
                        map.setCollisionOn(coordinate: nextStepCoordinate)
                    },
                    postCallback: {
                        map.removeCollisionOn(coordinate: nextStepCoordinate)
                        map.updateObjectPlacement(object, departure: preStepCoordinate, destination: nextStepCoordinate)
                    }
                )

                preStepCoordinate = nextStepCoordinate
                preStepPoint = nextStepPoint
            }

            _ = firstly {
                sender!.moveObject(
                    objectName!,
                    actions: objectActions,
                    tileDeparture: departure,
                    tileDestination: destination
                )
            }.always {
                let nextEventListener = InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                self.delegate?.invoke(self, listener: nextEventListener)
            }
        }
    }

    fileprivate func calcDestination(_ departure: TileCoordinate, direction: DIRECTION, step_num: Int) -> TileCoordinate {
        var diff: TileCoordinate = TileCoordinate(x: 0, y: 0)
        switch direction {
        case .up:
            diff = diff + TileCoordinate(x: 0, y: 1)
        case .down:
            diff = diff + TileCoordinate(x: 0, y: -1)
        case .right:
            diff = diff + TileCoordinate(x: 1, y: 0)
        case .left:
            diff = diff + TileCoordinate(x: -1, y: 0)
        }
        return (departure + diff)
    }
    
    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
