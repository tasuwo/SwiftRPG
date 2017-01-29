//
//  EnableWalkingEventListener.swift
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

class BackToDefaultStateEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)
        self.triggerType = .immediate
        self.invoke      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in

            sender!.enableWalking()
            sender!.startBehaviors()

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }
}

