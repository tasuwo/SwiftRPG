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

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .touch
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            _ = firstly {
                sender!.hideAllButtons()
            }.then { _ in
                sender!.showDefaultButtons()
            }

            do {
                // 次のリスナーが登録されていなければ終了
                if listeners == nil || listeners?.count == 0 { return }

                // 次のリスナーが登録されているなら，新たに invoke する
                let nextListener = listeners!.first!.listener
                let nextListenerChain: ListenerChain? = listeners!.count == 1 ? nil : Array(listeners!.dropFirst())
                let nextListenerInstance = try nextListener.init(params: listeners!.first!.params, chainListeners: nextListenerChain)
                self.delegate?.invoke(self, listener: nextListenerInstance)
            } catch {
                throw error
            }
        }
    }
}
