//
//  RenderDefaultViewEventListener.swift
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

class RenderDefaultViewEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)

        self.triggerType = .immediate
        self.invoke = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true
            
            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.hideAllButtons()
                }.then { _ in
                    sender!.showDefaultButtons()
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

