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

class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .Button
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene
            let map        = scene.map

            scene.actionButton.hidden = true
            scene.menuButton.hidden = true

            let maxIndex = params?.arrayObject?.count
            if let direction = params![maxIndex!-1]["direction"].string {
                let player = map.getObjectByName(objectNameTable.PLAYER_NAME)
                player?.setDirection(DIRECTION.fromString(direction)!)
            }

            TalkEventListener.getListener(0, params: params!)(sender: sender, args: args)

            // TODO: index < 1 のときの処理
            self.delegate?.invoke(self, listener: TalkEventListener(params: params!, chainListeners: listeners, index: 1))
        }
    }
}

class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    internal required convenience init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.init(params: params, chainListeners: listeners, index: 0)
    }

    init(params: JSON?, chainListeners listeners: ListenerChain?, index: Int) {
        self.triggerType = .Touch
        self.executionType = .Onece

        var updatedParams = params
        let maxIndex = params?.arrayObject?.count
        if params![maxIndex!-1]["direction"].string != nil {
            var array = params!.arrayObject as? [[String:String]]
            array?.removeLast()
            updatedParams = JSON(array!)
        }

        let updatedMaxIndex = updatedParams?.arrayObject?.count
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            if index < updatedMaxIndex!-1 {
                TalkEventListener.getListener(index, params: updatedParams!)(sender: sender, args: args)
                self.delegate?.invoke(self, listener: TalkEventListener(params: updatedParams!, chainListeners: listeners, index: index+1))
            } else {
                TalkEventListener.getListener(index, params: updatedParams!)(sender: sender, args: args)
                self.delegate?.invoke(self, listener: EndTalkEventListener(params: params, chainListeners: listeners))
            }
        }
    }

    static func getListener(index: Int, params: JSON) -> EventMethod {
        return {
            sender, args in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene
            let map        = scene.map
            let sheet      = map.sheet

            let talker = params[index]["talker"].string
            let talkBody = params[index]["talk_body"].string
            let talkSideString = params[index]["talk_side"].string
            if talker == nil || talkBody == nil || talkSideString == nil {
                print("Some required params are missing")
                return
            }

            let talkSide: Dialog.TALK_SIDE
            switch talkSideString! {
            case "L": talkSide = .left
            case "R": talkSide = .right
            default:
                print("Invalid talk side param")
                return
            }
            
            let talkerImageName = TALKER_IMAGE[talker!]
            if talkerImageName == nil {
                print("Invalid talker image name")
                return
            }

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

class EndTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
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
            let nextParams = listeners?.first?.params
            let nextChainListeners = Array(listeners!.dropFirst())
            self.delegate!.invoke(self, listener: nextListener!.init(params: nextParams, chainListeners: nextChainListeners))
        }
    }
}
