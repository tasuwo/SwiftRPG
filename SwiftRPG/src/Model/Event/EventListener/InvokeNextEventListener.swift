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
    let triggerType: TriggerType
    let executionType: ExecutionType
    internal var listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .immediate
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            do {
                // 次のリスナーが登録されていなければ終了
                if listeners == nil || listeners?.count == 0 { return }

                // 次のリスナーが登録されているなら，新たに invoke する
                let nextListener = listeners!.first!.listener
                let nextListenerChain: ListenerChain? = listeners!.count == 1 ? nil : Array(listeners!.dropFirst())
                let nextListenerInstance = try nextListener.init(params: listeners!.first!.params, chainListeners: nextListenerChain)
                self.delegate?.invoke(self, listener: nextListenerInstance)
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
