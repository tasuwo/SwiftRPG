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
    var rollback: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    var isExecuting: Bool = false
    var isBehavior: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.params        = params
        self.listeners     = listeners
        self.triggerType   = .touch
        self.rollback      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.actionButton.isHidden = true
            sender?.textBox.hide()
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true

            sender?.startBehaviors()
            
            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.textBox.hide(duration: 0)
                }.then { _ -> Void in
                    do {
                        let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                        nextEventListener.eventObjectId = self.eventObjectId
                        nextEventListener.isBehavior = self.isBehavior
                        self.delegate?.invoke(nextEventListener)
                    } catch {
                        throw error
                    }
                }.then {
                    fullfill()
                }.catch { error in
                    print(error.localizedDescription)
                }
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
