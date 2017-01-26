//
//  TouchEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON
import JSONSchema

/// プレイヤー移動のリスナー
class WalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners: ListenerChain?) {
        self.triggerType   = .touch
        self.executionType = .loop
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) in
            let schema = Schema([
                "type": "object",
                "properties": [
                    "touchedPoint": ["type": "string"],
                ],
                "required": ["touchedPoint"],
                ])
            let result = schema.validate(args?.rawValue ?? [])
            if result.valid == false {
                throw EventListenerError.illegalParamFormat(result.errors!)
            }
            // TODO: The following method end up throw exception even in the case the 'touchedPoint' value is (0,0).
            if CGPointFromString((args?["touchedPoint"].string)!) == CGPoint.init(x: 0, y: 0) {
                throw EventListenerError.illegalParamFormat(["The parameter 'touchedPoint' isn't castable to CGPoint."])
            }

            let map   = sender!.map!
            let sheet = map.sheet!

            let touchedPoint = CGPointFromString((args?["touchedPoint"].string)!)
            let player       = map.getObjectByName(objectNameTable.PLAYER_NAME)!
            let departure    = TileCoordinate.getTileCoordinateFromSheetCoordinate(player.position)
            var destination  = TileCoordinate.getTileCoordinateFromScreenCoordinate(
                sheet.getSheetPosition(),
                screenCoordinate: touchedPoint
            )

            // Route search
            let aStar = AStar(map: map)
            aStar.initialize(departure, destination: destination)
            let path = aStar.main()
            if path == nil { return }

            // Generate SKAction for moving
            var playerActions: Array<SKAction> = []
            var events: [EventListener] = []
            var preStepPoint = player.position
            for step: TileCoordinate in path! {
                let nextStePoint: CGPoint = TileCoordinate.getSheetCoordinateFromTileCoordinate(step)
                playerActions += player.getActionTo(preStepPoint, destination: nextStePoint)

                // If there were events on tile which is placed, stop moving and execute it.
                let eventsOnStep = map.getEventsOn(step)
                if eventsOnStep.count > 0 {
                    events = eventsOnStep
                    destination = step
                    break
                }
                preStepPoint = nextStePoint
            }

            // Generate SKAction for scrolling screen
            let delay = SKAction.wait(forDuration: TimeInterval(Double(player.speed * CGFloat(path!.count))))
            let scrollAction: SKAction? = sheet.scrollSheet(destination)
            var scrollActions: Array<SKAction> = []
            if scrollAction != nil {
                scrollActions.append(delay)
                scrollActions.append(scrollAction!)
            }

            sender!.movePlayer(
                playerActions,
                tileDeparture: departure,
                tileDestination: destination,
                events: events,
                screenActions: scrollActions)
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
