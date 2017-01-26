//
//  ActivateButtonListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/06.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit

class ActivateButtonListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        let schema = Schema([
            "type": "object",
            "properties": [
                "text": ["type": "string"],
            ],
            "required": ["text"],
        ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.params        = params
        self.listeners     = listeners
        self.triggerType   = .immediate
        self.executionType = .onece
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.actionButton.title = params!["text"].string!
            sender!.actionButton.isHidden = false

            do {
                let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                self.delegate?.invoke(self, listener: nextEventListener)
            } catch {
                throw error
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

