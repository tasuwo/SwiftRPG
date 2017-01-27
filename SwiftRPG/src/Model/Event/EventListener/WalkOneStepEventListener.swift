//
//  WalkOneStepEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/26.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON
import JSONSchema
import PromiseKit

class WalkOneStepEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var isExecuting: Bool = false
    var params: JSON?
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "destination": ["type": "string"],
            ],
            "required": ["destination"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.params        = params
        self.listeners     = chainListeners
        self.triggerType   = .immediate
        self.executionType = .onece
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) in
            self.isExecuting = true

            let map   = sender!.map!
            let sheet = map.sheet!

            let player      = map.getObjectByName(objectNameTable.PLAYER_NAME)!
            let destination = TileCoordinate.parse(from: (self.params?["destination"].string)!)

            // Generate SKAction for moving
            let action = player.getActionTo(
                player.position,
                destination: TileCoordinate.getSheetCoordinateFromTileCoordinate(destination)
            )

            // If player can't reach destination tile because of collision, stop
            if !map.canPass(destination) {
                self.delegate?.invoke(self, listener: WalkEventListener.init(params: nil, chainListeners: nil))
                return
            }

            // If there were events on tile which is placed, stop moving and execute it.
            var events: [EventListener] = []
            let eventsOnStep = map.getEventsOn(destination)
            if eventsOnStep.count > 0 {
                events = eventsOnStep
            }

            // Generate SKAction for scrolling screen
            let delay = SKAction.wait(forDuration: TimeInterval(Double(player.speed)))
            let scrollAction: SKAction? = sheet.scrollSheet(destination)
            var scrollActions: Array<SKAction> = []
            if scrollAction != nil {
                scrollActions.append(delay)
                scrollActions.append(scrollAction!)
            }

            firstly {
                sender!.movePlayer(
                    action,
                    tileDeparture: player.coordinate,
                    tileDestination: destination,
                    screenActions: scrollActions)
            }.then { _ -> Void in
                // If there are event on reached tile, invoke it
                if !events.isEmpty {
                    self.delegate?.invoke(self, listener: WalkEventListener.init(params: nil, chainListeners: nil))
                    sender?.registerEvent(listeners: events)
                    return
                }

                // If reached at destination, stop walking and set WalkEvetListener as touch event again
                if self.listeners == nil || self.listeners?.count == 0 {
                    let nextEventListener = WalkEventListener.init(params: nil, chainListeners: nil)
                    nextEventListener.eventObjectId = self.eventObjectId
                    self.delegate?.invoke(self, listener: nextEventListener)
                    return
                }

                // If player don't reach at destination, invoke next step animation listener
                let nextListener = self.listeners!.first!.listener
                let nextListenerChain: ListenerChain? = self.listeners!.count == 1 ? nil : Array(self.listeners!.dropFirst())
                do {
                    let nextListenerInstance = try nextListener.init(params: self.listeners!.first!.params, chainListeners: nextListenerChain)
                    self.delegate?.invoke(self, listener: nextListenerInstance)
                } catch {
                    throw error
                }
            }.catch { error in
                print(error.localizedDescription)
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
