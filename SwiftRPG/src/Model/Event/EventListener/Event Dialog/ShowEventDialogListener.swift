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

class ShowEventDialogListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var rollback: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType

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
        self.rollback      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.eventDialog.isHidden = true
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender!.eventDialog.text = params!["text"].string!
            sender!.eventDialog.isHidden = false

            let nextEventListener = HideEventDialogListener(params: self.params, chainListeners: self.listeners)
            nextEventListener.eventObjectId = self.eventObjectId
            self.delegate?.invoke(self, listener: nextEventListener)

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
