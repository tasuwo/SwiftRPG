//
//  TalkEventListeners.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var rollback: EventMethod?
    var isExecuting: Bool = false
    var isBehavior: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType

    fileprivate let params: JSON
    internal var listeners: ListenerChain?
    fileprivate let index: Int
    fileprivate let talkContentsMaxNum: Int

    required convenience init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        do {
            try self.init(params: params, chainListeners: listeners, index: 1)
        } catch {
            throw error
        }
    }

    init(params: JSON?, chainListeners listeners: ListenerChain?, index: Int) throws {

        // TODO:
        // The truth is validation as follows should be executed by JSONSchema,
        // but JSONSchema doesn't work well with nested JSON.
        // This is because that determine whether it's object or not by whether it's castable to NSDicationary
        // let schema = Schema([
        //   "type": "object",
        //   "minProperties": 1,
        // ])

        if params == nil { throw EventListenerError.illegalParamFormat(["Parameter is nil"]) }

        let maxIndex = params?.arrayObject?.count
        if maxIndex == nil { throw EventListenerError.illegalParamFormat(["No properties in json parameter"]) }

        self.params        = params!
        self.listeners     = listeners
        self.index         = index
        self.triggerType   = .touch
        // TODO: The value of following variable is determined by the number of property.
        //       It might have to be defined specifically.
        // a number of conversation times
        self.talkContentsMaxNum = (params?.arrayObject?.count)!
        self.rollback        = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            sender?.actionButton.isHidden = true
            sender?.textBox.hide()
            return Promise<Void> { fullfill, reject in fullfill() }
        }
        self.invoke = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            do {
                let moveConversation = try TalkEventListener.generateMoveConversationMethod(self.index, params: self.params)
                try moveConversation(sender, args).catch { error in
                    // TODO
                }

                // Determine the Event Listener which executed in next 
                // depending on whether conversation is continued or not.
                let nextEventListener: EventListener
                if index < self.talkContentsMaxNum - 1 {
                    nextEventListener = try TalkEventListener(params: self.params, chainListeners: self.listeners, index: self.index+1)
                } else {
                    nextEventListener = try FinishTalkEventListener(params: self.params, chainListeners: self.listeners)
                }
                nextEventListener.eventObjectId = self.eventObjectId
                nextEventListener.isBehavior = self.isBehavior
                
                self.delegate?.invoke(self, listener: nextEventListener)
            } catch {
                throw error
            }

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }

    static func generateMoveConversationMethod(_ index: Int, params: JSON) throws -> EventMethod {
        let schema = Schema([
            "type": "object",
            "properties": [
                "talker": ["type": "string"],
                "talk_body": ["type": "string"],
                "talk_side": [
                    "type": "string",
                    "enum": ["L", "R"]
                ],
            ],
            "required": ["talker", "talk_body", "talk_side"],
        ])
        let result = schema.validate(params[index].rawValue)
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        if TALKER_IMAGE.index(forKey: params[index]["talker"].string!) == nil {
            throw EventListenerError.invalidParam("Talker image name specified at param `talker` is not declared in configuration file")
        }

        let talker          = params[index]["talker"].string!
        let talkBody        = params[index]["talk_body"].string!
        let talkSideString  = params[index]["talk_side"].string!
        let talkSide        = talkSideString == "L" ? Dialog.TALK_SIDE.left : Dialog.TALK_SIDE.right
        let talkerImageName = TALKER_IMAGE[talker]

        return { sender, args in
            sender!.textBox.drawText(talkerImageName, body: talkBody, side: talkSide)
            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
