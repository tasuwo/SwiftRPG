//
//  TalkEventListeners.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit

/// 会話開始のリスナー．
class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    private let directionString: String
    private let params: JSON
    private let listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .Button
        self.executionType = .Onece

        if params == nil {
            throw EventListenerError.ParamIsNil
        }

        let maxIndex = params!.arrayObject?.count
        if maxIndex == nil {
            throw EventListenerError.IllegalParamFormat("Cannot count the number of params at StartTalkEventListener")
        }

        let directionString = params![maxIndex!-1]["direction"].string
        if directionString == nil {
            throw EventListenerError.IllegalParamFormat(EventListenerError.generateIllegalParamFormatErrorMessage(
                ["direction": directionString],
                handler: StartTalkEventListener.self)
            )
        }
        self.directionString = directionString!

        // "direction" を params から取り除く
        var array = params!.arrayObject as? [[String:String]]
        array?.removeLast()
        self.params = JSON(array!)
        self.listeners = listeners

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene
            let map        = scene.map

            scene.actionButton.hidden = true
            scene.menuButton.hidden = true

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
                try nextTalkEventMethod(sender: sender, args: args)
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
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    private let params: JSON
    private let listeners: ListenerChain?
    private let index: Int
    private let talkContentsMaxNum: Int

    required convenience init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        do {
            try self.init(params: params, chainListeners: listeners, index: 1)
        } catch {
            throw error
        }
    }

    init(params: JSON?, chainListeners listeners: ListenerChain?, index: Int) throws {
        self.triggerType = .Touch
        self.executionType = .Onece

        if params == nil {
            throw EventListenerError.ParamIsNil
        }
        self.params = params!
        self.listeners = listeners
        self.index = index

        let talkContentsMaxNum = params!.arrayObject?.count
        if talkContentsMaxNum == nil {
            throw EventListenerError.IllegalParamFormat("Cannot count the number of params at StartTalkEventListener")
        }
        self.talkContentsMaxNum = talkContentsMaxNum!

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in

            let nextTalkEventMethod: EventMethod
            do {
                nextTalkEventMethod = try TalkEventListener.generateEventMethod(self.index, params: self.params)
            } catch {
                throw error
            }

            do {
                try nextTalkEventMethod(sender: sender, args: args)
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

    static func generateEventMethod(index: Int, params: JSON) throws -> EventMethod {
        let talker = params[index]["talker"].string
        let talkBody = params[index]["talk_body"].string
        let talkSideString = params[index]["talk_side"].string
        if talker == nil || talkBody == nil || talkSideString == nil {
            throw EventListenerError.IllegalParamFormat(EventListenerError.generateIllegalParamFormatErrorMessage(
                ["talker": talker, "talk_body": talkBody, "talk_side": talkSideString],
                handler: TalkEventListener.self)
            )
        }

        let talkSide: Dialog.TALK_SIDE
        switch talkSideString! {
        case "L": talkSide = .left
        case "R": talkSide = .right
        default:
            throw EventListenerError.InvalidParam("Param `talk_side`'s value is invalid at TalkEventListener")
        }
            
        let talkerImageName = TALKER_IMAGE[talker!]
        if talkerImageName == nil {
            throw EventListenerError.InvalidParam("Talker image name specified at param `talker` is not declared in configuration file")
        }

        return {
            sender, args in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene
            let map        = scene.map
            let sheet      = map.sheet

            // 画面上のプレイヤーの位置を取得
            let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
            let playerPosition = TileCoordinate.getSheetCoordinateFromScreenCoordinate(
                sheet!.getSheetPosition(),
                screenCoordinate: player!.getRealTimePosition()
            )

            // キャラクターとかぶらないように，テキストボックスの位置を調整
            var DialogPosition: Dialog.POSITION
            if playerPosition.y <= scene.frame.height / 2 {
                DialogPosition = Dialog.POSITION.top
            } else {
                DialogPosition = Dialog.POSITION.bottom
            }
            scene.textBox_.show(DialogPosition)

            // テキスト描画
            scene.textBox_.drawText(talkerImageName!, body: talkBody!, side: talkSide)
        }
    }
}

/// 会話終了のリスナー
class EndTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .Touch
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene

            scene.textBox_.hide()
            scene.menuButton.hidden = false

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
