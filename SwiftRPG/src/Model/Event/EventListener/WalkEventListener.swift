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
        self.executionType = .onece
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
            let destination  = TileCoordinate.getTileCoordinateFromScreenCoordinate(
                sheet.getSheetPosition(),
                screenCoordinate: touchedPoint
            )

            // Route search
            let aStar = AStar(map: map)
            aStar.initialize(departure, destination: destination)
            let path = aStar.main()
            if path == nil {
                self.delegate?.invoke(self, listener: WalkEventListener.init(params: nil, chainListeners: nil))
                return
            }

            // Generate event listener chain for walking animation
            var chain: ListenerChain = []
            for step: TileCoordinate in path! {
                chain = chain + self.generateOneStepWalkListener(step)
            }

            let nextListener = chain.first!.listener
            let nextListenerChain: ListenerChain? = chain.count == 1 ? nil : Array(chain.dropFirst())
            do {
                let nextListenerInstance = try nextListener.init(params: chain.first!.params, chainListeners: nextListenerChain)
                self.delegate?.invoke(self, listener: nextListenerInstance)
            } catch {
                throw error
            }
        }
    }

    fileprivate func generateOneStepWalkListener(_ destination: TileCoordinate) -> ListenerChain {
        return [ (listener: WalkOneStepEventListener.self, params: JSON(["destination": destination.description])) ]
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
