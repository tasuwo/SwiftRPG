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

class FinishTalkEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)

        self.triggerType   = .touch
        self.rollback      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.actionButton.isHidden = true
            sender?.textBox.hide()
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true
            
            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.textBox.hide(duration: 0)
                }.then { _ -> Void in
                    do {
                        let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                        nextEventListener.eventObjectId = self.eventObjectId
                        nextEventListener.isBehavior = self.isBehavior
                        self.delegate?.invoke(nextEventListener, invoker: self)
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
}
