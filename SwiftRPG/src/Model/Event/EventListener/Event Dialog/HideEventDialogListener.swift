//
//  HideEventDialogListener.swift
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

class HideEventDialogListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        try! super.init(params: params, chainListeners: listeners)

        self.triggerType   = .touch
        self.rollback        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.eventDialog.isHidden = true
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender!.eventDialog.isHidden = true

            sender?.startBehaviors()

            do {
                let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                nextEventListener.eventObjectId = self.eventObjectId
                nextEventListener.isBehavior = self.isBehavior
                self.delegate?.invoke(nextEventListener)
            } catch {
                throw error
            }

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}
