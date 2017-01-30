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

class ReloadBehaviorEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)

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

        self.triggerType   = .immediate
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            let map   = sender!.map!
            let id = self.params?["eventObjectId"].int!

            // TODO: Implement utility function for generate listener from behavior listener chain
            var listener: EventListener? = nil
            let listenerChain = map.getObjectBehavior(id!)
            let listenerType = listenerChain?.first?.listener
            let params = listenerChain?.first?.params
            do {
                listener = try listenerType?.init(
                    params: params,
                    chainListeners: ListenerChain(listenerChain!.dropFirst(1)))
                listener?.eventObjectId = id
                listener?.isBehavior = true
            } catch {
                // TODO
            }

            self.delegate?.invoke(listener!, invoker: self)

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}
