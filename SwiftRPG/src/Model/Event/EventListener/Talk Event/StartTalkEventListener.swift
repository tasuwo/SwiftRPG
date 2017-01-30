//
//  StartTalkEventListener.swift
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

class StartTalkEventListener: EventListenerImplement {
    fileprivate var directionString: String

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        if params == nil { throw EventListenerError.illegalParamFormat(["Parameter is nil"]) }

        let maxIndex = params?.arrayObject?.count
        if maxIndex == nil { throw EventListenerError.illegalParamFormat(["No properties in json parameter"]) }

        let directionString = params![maxIndex!-1]["direction"].string
        // Remove "direction" from params
        var array = params!.arrayObject as? [[String:String]]
        array?.removeLast()

        self.directionString = directionString!

        try! super.init(params: params, chainListeners: listeners)

        self.triggerType     = .button
        self.params          = JSON(array!)
        self.rollback        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.actionButton.isHidden = true
            sender?.textBox.hide()
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke          = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            self.isExecuting = true

            // Initialize dialog
            sender?.textBox.clean()

            // Stop All Object's behavior
            sender?.stopBehaviors()
            sender?.disableWalking()

            // Change direction of player
            let map = sender!.map!
            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            if let playerDirection = DIRECTION.fromString(self.directionString) {
                player?.setDirection(playerDirection)
            }

            return Promise<Void> { fullfill, reject in
                firstly {
                    sender!.hideAllButtons()
                }.then {
                    sender!.textBox.show(duration: 0.2)
                }.then { _ -> Void in
                    do {
                        // Render next conversation
                        let moveConversation = try TalkEventListener.generateMoveConversationMethod(0, params: self.params!)
                        try moveConversation(_: sender, args).catch { error in
                            // TODO
                        }

                        // TODO: If there are no need to invoke following (i.e. The conversation would finish in only one(above) step),
                        //       should deal with it well.
                        let nextEventListener = try TalkEventListener(params: self.params, chainListeners: self.listeners)
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
