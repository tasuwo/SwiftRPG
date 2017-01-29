//
//  ActivateEventDialogListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/23.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class ShowEventDialogListener: EventListenerImplement {
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

        self.triggerType   = .immediate
        self.rollback      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.eventDialog.isHidden = true
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender!.eventDialog.text = params!["text"].string!
            sender!.eventDialog.isHidden = false

            // Stop All Object's behavior
            sender?.stopBehaviors()

            let nextEventListener = HideEventDialogListener(params: self.params, chainListeners: self.listeners)
            nextEventListener.eventObjectId = self.eventObjectId
            nextEventListener.isBehavior = self.isBehavior
            self.delegate?.invoke(nextEventListener)

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}
