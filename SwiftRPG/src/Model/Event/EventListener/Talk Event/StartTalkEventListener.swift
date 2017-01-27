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

class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var rollback: EventMethod?
    var isExecuting: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let directionString: String
    fileprivate let params: JSON
    internal var listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {

        if params == nil { throw EventListenerError.illegalParamFormat(["Parameter is nil"]) }

        let maxIndex = params?.arrayObject?.count
        if maxIndex == nil { throw EventListenerError.illegalParamFormat(["No properties in json parameter"]) }

        let directionString = params![maxIndex!-1]["direction"].string
        // Remove "direction" from params
        var array = params!.arrayObject as? [[String:String]]
        array?.removeLast()

        self.directionString = directionString!
        self.triggerType     = .button
        self.executionType   = .onece
        self.params          = JSON(array!)
        self.listeners       = listeners
        self.rollback        = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender?.actionButton.isHidden = true
        }
        self.invoke          = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            // Initialize dialog
            sender!.textBox.clean()

            // Change direction of player
            let map = sender!.map!
            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            if let playerDirection = DIRECTION.fromString(self.directionString) {
                player?.setDirection(playerDirection)
            }

            firstly {
                sender!.hideAllButtons()
            }.then {
                sender!.textBox.show(duration: 0.2)
            }.then { _ -> Void in
                do {
                    // Render next conversation
                    let moveConversation = try TalkEventListener.generateMoveConversationMethod(0, params: self.params)
                    try moveConversation(_: sender, args)

                    // TODO: If there are no need to invoke following (i.e. The conversation would finish in only one(above) step),
                    //       should deal with it well.
                    let nextEventListener = try TalkEventListener(params: self.params, chainListeners: self.listeners)
                    nextEventListener.eventObjectId = self.eventObjectId
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
