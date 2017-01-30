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
import PromiseKit

class ActivateButtonListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)
        
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

        self.triggerType = .immediate
        self.invoke      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender!.actionButton.title = self.params!["text"].string!
            sender!.actionButton.isHidden = false

            do {
                let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                nextEventListener.eventObjectId = self.eventObjectId
                nextEventListener.isBehavior = self.isBehavior
                self.delegate?.invoke(nextEventListener, invoker: self)
            } catch {
                throw error
            }

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}

