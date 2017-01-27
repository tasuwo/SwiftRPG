//
//  WaitEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/25.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON
import JSONSchema
import PromiseKit

class WaitEventListener: EventListener {
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
                "time": ["type": "string"]
            ],
            "required": ["time"],
            ]
        )
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        // TODO: Validation as following must be executed as a part of validation by JSONSchema
        if (Int(params!["time"].string!) == nil) {
            throw EventListenerError.illegalParamFormat(["The parameter 'time' couldn't convert to integer"])
        }

        self.params        = params
        self.listeners     = chainListeners
        self.triggerType   = .immediate
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true

            let map = sender!.map!
            let time = Int((self.params?["time"].string!)!)!

            return Promise<Void> { fullfill, reject in
                firstly {
                    self.generatePromiseClojureForWaiting(map: map, time: time)
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

    // TODO: Currently, for delaying animated, run delay action for Map SKSpriteNode.
    //       This might be problem if we wanted to animate map.
    fileprivate func generatePromiseClojureForWaiting(map: Map, time: Int) -> Promise<Void> {
        return Promise<Void> {
            fullfill, reject in
            map.wait(time, callback: { () in fullfill() })
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
