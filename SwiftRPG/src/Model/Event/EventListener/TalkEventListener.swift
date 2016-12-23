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

/// 会話開始のリスナー．
class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let directionString: String
    fileprivate let params: JSON
    fileprivate let listeners: ListenerChain?

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

        self.invoke = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            let map = sender!.map!

            sender!.actionButton.isHidden = true
            sender!.menuButton.isHidden = true

            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            if let playerDirection = DIRECTION.fromString(self.directionString) {
                player?.setDirection(playerDirection)
            }

            let nextTalkEventMethod: EventMethod
            do {
                nextTalkEventMethod = try TalkEventListener.generateEventMethod(0, params: self.params)
            } catch {
                throw error
            }

            do {
                try nextTalkEventMethod(_: sender, args)
            } catch {
                throw error
            }

            // TODO: index < 1 のときの処理
            do {
                self.delegate?.invoke(self, listener: try TalkEventListener(params: self.params, chainListeners: self.listeners))
            } catch {
                throw error
            }
        }
    }
}

/// 会話進行のリスナー
class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let params: JSON
    fileprivate let listeners: ListenerChain?
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

            let nextTalkEventMethod: EventMethod
            do {
                nextTalkEventMethod = try TalkEventListener.generateEventMethod(self.index, params: self.params)
            } catch {
                throw error
            }

            do {
                try nextTalkEventMethod(sender, args)
            } catch {
                throw error
            }

            let nextEventListener: EventListener
            do {
                if index < self.talkContentsMaxNum - 1 {
                    nextEventListener = try TalkEventListener(params: self.params, chainListeners: self.listeners, index: self.index+1)
                } else {
                    nextEventListener = try EndTalkEventListener(params: self.params, chainListeners: self.listeners)
                }
            } catch {
                throw error
            }

            self.delegate?.invoke(self, listener: nextEventListener)
        }
    }

    static func generateEventMethod(_ index: Int, params: JSON) throws -> EventMethod {

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
            let map   = sender!.map!
            let sheet = map.sheet

            // 画面上のプレイヤーの位置を取得
            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            let playerPosition = TileCoordinate.getSheetCoordinateFromScreenCoordinate(
                sheet!.getSheetPosition(),
                screenCoordinate: player!.getRealTimePosition()
            )

            // キャラクターとかぶらないように，テキストボックスの位置を調整
            var DialogPosition: Dialog.POSITION = .bottom
            /*if playerPosition.y <= scene.frame.height / 2 {
                DialogPosition = Dialog.POSITION.top
            } else {
                DialogPosition = Dialog.POSITION.bottom
            }*/
            sender!.textBox.show(DialogPosition)

            // テキスト描画
            sender!.textBox.drawText(talkerImageName!, body: talkBody!, side: talkSide)
        }
    }
}

/// 会話終了のリスナー
class EndTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .touch
        self.executionType = .onece

        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.textBox.hide()
            sender!.menuButton.isHidden = false

            if listeners?.count == 0 || listeners == nil { return }
            let nextListener = listeners?.first?.listener
            let nextListenerChain: ListenerChain? = listeners?.count == 1 ? nil : Array(listeners!.dropFirst())
            let nextListenerInstance: EventListener
            do {
                nextListenerInstance = try nextListener!.init(params: listeners?.first?.params, chainListeners: nextListenerChain)
            } catch {
                throw error
            }
            self.delegate?.invoke(self, listener: nextListenerInstance)
        }
    }
}
