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
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "time": ["type": "string"]
            ],
            "required": ["time"],
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
            let map = sender!.map!
            let time = self.params?["time"].string!
            _ = firstly {
                return Promise<Void> { fulfill, reject in
                    map.wait(Int(time!)!, callback: {() in fulfill()})
                }
            }.always {
                let nextEventListener = InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                self.delegate?.invoke(self, listener: nextEventListener)
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
