//
//  LoadBehaviorEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/28.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class ReloadBehaviorEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var rollback: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var eventObjectId: MapObjectId? = nil
    var isExecuting: Bool = false
    var isBehavior: Bool = false
    let triggerType: TriggerType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        let schema = Schema([
            "type": "object",
            "properties": [
                "text": ["eventObjectId": "int"],
            ],
            "required": ["eventObjectId"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        if params?["eventObjectId"].int == nil {
            throw EventListenerError.illegalParamFormat(["parameter 'eventObjectId' cannot convert to int"])
        }

        self.params        = params
        self.listeners     = listeners
        self.triggerType   = .immediate
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            let map   = sender!.map!
            let id = self.params?["eventObjectId"].int!
            let listener = map.getObjectBehavior(id!)
            listener?.eventObjectId = self.eventObjectId
            listener?.isExecuting = false
            listener?.isBehavior = self.isBehavior

            self.delegate?.invoke(self, listener: listener!)

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
