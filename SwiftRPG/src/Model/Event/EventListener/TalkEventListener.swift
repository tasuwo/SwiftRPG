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

/// 会話開始のリスナー．
class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let directionString: String
    fileprivate let params: JSON
    internal var listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {

        // JSONSchema で判定したいが，JSONSchema は入れ子になっている JSON を扱えない
        // これは，object の判定を NSDictionary へキャスト可能かどうかで判定しているため
        if params == nil { throw EventListenerError.illegalParamFormat(["Parameter is nil"]) }

        let maxIndex = params?.arrayObject?.count
        if maxIndex == nil { throw EventListenerError.illegalParamFormat(["No properties in json parameter"]) }

        let directionString = params![maxIndex!-1]["direction"].string
        // "direction" を params から取り除く
        var array = params!.arrayObject as? [[String:String]]
        array?.removeLast()

        self.directionString = directionString!
        self.triggerType = .button
        self.executionType = .onece
        self.params = JSON(array!)
        self.listeners = listeners
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in

            // ダイアログ初期化
            sender!.textBox.clean()

            // プレイヤーの向きの変更
            let map = sender!.map!
            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            if let playerDirection = DIRECTION.fromString(self.directionString) {
                player?.setDirection(playerDirection)
            }

            _ = firstly {
                sender!.hideAllButtons()
            }.then {
                _ in
                sender!.textBox.show(duration: 0.2)
            }.always {
                do {
                    // 会話を1つ進める
                    let moveConversation = try TalkEventListener.generateMoveConversationMethod(0, params: self.params)
                    try moveConversation(_: sender, args)

                    // TODO: index < 1 のとき = ここで会話が終了する時
                    self.delegate?.invoke(self, listener: try TalkEventListener(params: self.params, chainListeners: self.listeners))
                } catch {
                    // throw error

                    // TODO: 例外を外に投げたいがどうするか
                    print(error)
                }
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

/// 会話進行のリスナー
class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var isExecuting: Bool = false
    let triggerType: TriggerType
    let executionType: ExecutionType

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

        // JSONSchema で判定したいが，JSONSchema は入れ子になっている JSON を扱えない
        // これは，object の判定を NSDictionary へキャスト可能かどうかで判定しているため
        // let schema = Schema([
        //   "type": "object",
        //   "minProperties": 1,
        // ])

        if params == nil { throw EventListenerError.illegalParamFormat(["Parameter is nil"]) }

        let maxIndex = params?.arrayObject?.count
        if maxIndex == nil { throw EventListenerError.illegalParamFormat(["No properties in json parameter"]) }

        self.params = params!
        self.listeners = listeners
        self.index = index
        self.triggerType = .touch
        self.executionType = .onece
        // 会話の回数をプロパティ数から判断している．明示的にすべき？
        self.talkContentsMaxNum = (params?.arrayObject?.count)!
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in

            do {
                let moveConversation = try TalkEventListener.generateMoveConversationMethod(self.index, params: self.params)
                try moveConversation(sender, args)

                // 会話の継続，終了に応じて次の EventListener を決定
                let nextEventListener: EventListener
                if index < self.talkContentsMaxNum - 1 {
                    nextEventListener = try TalkEventListener(params: self.params, chainListeners: self.listeners, index: self.index+1)
                } else {
                    nextEventListener = try FinishTalkEventListener(params: self.params, chainListeners: self.listeners)
                }
                
                self.delegate?.invoke(self, listener: nextEventListener)
            } catch {
                throw error
            }
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

        let talker = params[index]["talker"].string!
        let talkBody = params[index]["talk_body"].string!
        let talkSideString = params[index]["talk_side"].string!
        let talkSide: Dialog.TALK_SIDE = talkSideString == "L" ? .left : .right
        let talkerImageName = TALKER_IMAGE[talker]

        return {
            sender, args in
            // テキスト描画
            sender!.textBox.drawText(talkerImageName, body: talkBody, side: talkSide)
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

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
        self.params = params
        self.listeners = listeners
        self.triggerType = .touch
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            _ = firstly {
                sender!.textBox.hide(duration: 0)
            }.always {
                let nextEventListener = InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                self.delegate?.invoke(self, listener: nextEventListener)
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
