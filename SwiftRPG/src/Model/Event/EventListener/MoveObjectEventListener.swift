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

class MoveObjectEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "name": ["type": "string"]
            ],
            "required": ["name"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.params = params
        self.triggerType = .immediate
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) in
            let map   = sender!.map!

            let objectName = self.params?["name"].string!

            let object = map.getObjectByName(objectName!)!
            object.setSpeed(100)
            let departure = object.coordinate
            let destination = departure + TileCoordinate(x: 1, y: 0)

            // Route search by A* algorithm
            let aStar = AStar(map: map)
            aStar.initialize(departure, destination: destination)
            let path = aStar.main()
            if path == nil { return }

            // Define action for moving
            var objectActions: Array<SKAction> = []
            var preStepPoint = object.position
            for step: TileCoordinate in path! {
                let nextStepPoint: CGPoint = TileCoordinate.getSheetCoordinateFromTileCoordinate(step)
                objectActions += object.getActionTo(preStepPoint, destination: nextStepPoint)
                preStepPoint = nextStepPoint
            }

            // Move
            sender!.moveObject(
                objectName!,
                actions: objectActions,
                tileDeparture: departure,
                tileDestination: destination)
        }
    }
    
    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
