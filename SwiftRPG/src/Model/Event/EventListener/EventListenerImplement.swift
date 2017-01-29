//
//  EventListenerImplement.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/29.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class EventListenerImplement: EventListener {
    var id:            UInt64!
    var delegate:      NotifiableFromListener? = nil
    var invoke:        EventMethod? = nil
    var rollback:      EventMethod? = nil
    var listeners:     ListenerChain? = nil
    var params:        JSON? = nil
    var eventObjectId: MapObjectId? = nil
    var isExecuting:   Bool = false
    var isBehavior:    Bool = false
    var triggerType:   TriggerType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.params      = params
        self.listeners   = listeners
        self.triggerType = .immediate
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

