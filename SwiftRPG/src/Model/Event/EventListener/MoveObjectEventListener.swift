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
    var rollback: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    var isBehavior: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType

    required init(params: JSON?, chainListeners: ListenerChain?) throws {
        let schema = Schema([
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "direction": [
                    "type":"string",
                    "enum": ["LEFT", "RIGHT", "UP", "DOWN"]
                ],
                "step_num": ["type":"string"],
                "speed": ["type":"string"]
            ],
            "required": ["name", "direction", "step_num", "speed"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        // TODO: Validation as following must be executed as a part of validation by JSONSchema
        if (Int(params!["step_num"].string!) == nil) {
            throw EventListenerError.illegalParamFormat(["The parameter 'step_num' couldn't convert to integer"])
        }
        if (Int(params!["speed"].string!) == nil) {
            throw EventListenerError.illegalParamFormat(["The parameter 'speed' couldn't convert to integer"])
        }

        self.params        = params
        self.listeners     = chainListeners
        self.triggerType   = .immediate
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true

            let map   = sender!.map!

            let objectName = self.params?["name"].string!
            let direction  = DIRECTION.fromString((self.params?["direction"].string!)!)
            let step_num   = Int((self.params?["step_num"].string!)!)
            let speed      = Int((self.params?["speed"].string!)!)

            let object = map.getObjectByName(objectName!)!
            object.setDirection(direction!)
            object.setSpeed(CGFloat(speed!))

            // Route search by A* algorithm
            let departure = object.coordinate
            let destination = self.calcDestination(departure, direction: direction!, step_num: step_num!)

            let aStar = AStar(map: map)
            aStar.initialize(departure, destination: destination)
            let route = aStar.main()
            if route == nil {
                // If there are no route to destination, finish this listener and invoke next listener
                do {
                    let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                    nextEventListener.eventObjectId = self.eventObjectId
                    nextEventListener.isBehavior = self.isBehavior
                    self.delegate?.invoke(self, listener: nextEventListener)
                } catch {
                    throw error
                }
                return Promise<Void> { fullfill, reject in fullfill() }
            }

            // Disable events
            // Remove all events related to object from map
            map.removeEventsOfObject(object.id)

            // Define action for moving
            var objectActions: Array<SKAction> = []
            var preStepCoordinate = object.coordinate
            var preStepPoint = object.position
            for nextStepCoordinate: TileCoordinate in route! {
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

            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.moveObject(
                        objectName!,
                        actions: objectActions,
                        tileDeparture: departure,
                        tileDestination: destination
                    )
                }.then { _ -> Void in
                    do {
                        let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                        nextEventListener.eventObjectId = self.eventObjectId
                        nextEventListener.isBehavior = self.isBehavior
                        self.delegate?.invoke(self, listener: nextEventListener)
                    } catch {
                        throw error
                    }
                }.then {
                    fullfill()
                }.catch { error in
                    print(error.localizedDescription)
                }
            }
        }
    }

    fileprivate func calcDestination(_ departure: TileCoordinate, direction: DIRECTION, step_num: Int) -> TileCoordinate {
        var diff: TileCoordinate = TileCoordinate(x: 0, y: 0)
        switch direction {
        case .up:
            diff = diff + TileCoordinate(x:  0, y:  1)
        case .down:
            diff = diff + TileCoordinate(x:  0, y: -1)
        case .right:
            diff = diff + TileCoordinate(x:  1, y:  0)
        case .left:
            diff = diff + TileCoordinate(x: -1, y:  0)
        }
        return (departure + diff)
    }
    
    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
