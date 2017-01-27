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
    var rollback: EventMethod?
    var listeners: ListenerChain?
    var isExecuting: Bool = false
    var params: JSON?
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType

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
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
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
                return Promise<Void> { fullfill, reject in fullfill() }
            }

            // Generate SKAction for scrolling screen
            let delay = SKAction.wait(forDuration: TimeInterval(Double(player.speed)))
            let scrollAction: SKAction? = sheet.scrollSheet(destination)
            var scrollActions: Array<SKAction> = []
            if scrollAction != nil {
                scrollActions.append(delay)
                scrollActions.append(scrollAction!)
            }

            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.movePlayer(
                        action,
                        tileDeparture: player.coordinate,
                        tileDestination: destination,
                        screenActions: scrollActions)
                }.then { _ -> Void in
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
                }.then {
                    fullfill()
                }.catch { error in
                    print(error.localizedDescription)
                }
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
