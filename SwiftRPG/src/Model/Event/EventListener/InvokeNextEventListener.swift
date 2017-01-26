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

class InvokeNextEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType
    internal var listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType   = .immediate
        self.executionType = .onece
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            // If there are no registered listener, exit
            if listeners == nil || listeners?.count == 0 { return }

            // If there are registered listener, invoke it
            let nextListener = listeners!.first!.listener
            let nextListenerChain: ListenerChain? = listeners!.count == 1 ? nil : Array(listeners!.dropFirst())
            do {
                let nextListenerInstance = try nextListener.init(params: listeners!.first!.params, chainListeners: nextListenerChain)
                self.delegate?.invoke(self, listener: nextListenerInstance)
            } catch {
                throw error
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
