//
//  InvokeNextEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/23.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import PromiseKit

class InvokeNextEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)

        self.triggerType   = .immediate
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            // If there are no registered listener, exit
            if listeners == nil || listeners?.count == 0 {
                return Promise<Void> { fullfill, reject in fullfill() }
            }

            // If there are registered listener, invoke it
            let nextListener = listeners!.first!.listener
            let nextListenerChain: ListenerChain? = listeners!.count == 1 ? nil : Array(listeners!.dropFirst())
            do {
                let nextListenerInstance = try nextListener.init(params: listeners!.first!.params, chainListeners: nextListenerChain)
                nextListenerInstance.eventObjectId = self.eventObjectId
                nextListenerInstance.isBehavior = self.isBehavior
                self.delegate?.invoke(nextListenerInstance)
            } catch {
                throw error
            }

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}
