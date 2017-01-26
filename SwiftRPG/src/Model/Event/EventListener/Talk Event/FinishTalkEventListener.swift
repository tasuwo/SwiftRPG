//
//  FinishTalkEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/26.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class FinishTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.params        = params
        self.listeners     = listeners
        self.triggerType   = .touch
        self.executionType = .onece
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            firstly {
                sender!.textBox.hide(duration: 0)
                }.then { _ -> Void in
                    do {
                        let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                        self.delegate?.invoke(self, listener: nextEventListener)
                    } catch {
                        throw error
                    }
                }.catch { error in
                    print(error.localizedDescription)
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
