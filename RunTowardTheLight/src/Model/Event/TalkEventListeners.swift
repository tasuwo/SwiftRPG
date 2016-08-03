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

class ActivateButtonListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType

    init(params: JSON?) {
        self.triggerType = .Immediate
        self.executionType = .Onece
        self.invoke = { (sender: AnyObject!, args: JSON!) -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            scene.actionButton.titleLabel?.text = "はなす"

            scene.actionButton.hidden = false

            self.delegate?.invoke(self, listener: StartTalkEventListener(params: params))
        }
    }
}

class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType

    init(params: JSON?) {
        self.triggerType = .Button
        self.executionType = .Onece
        self.invoke = { (sender: AnyObject!, args: JSON!) -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene
            
            scene.actionButton.hidden = true

            TalkEventListener.getListener(0, params: params!)(sender: sender, args: args)
            
            self.delegate?.invoke(self, listener: TalkEventListener(params: params))
        }
    }
}

class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType = .Touch
    private(set) var executionType: ExecutionType = .Loop
    var params: JSON?
    var events: [(sender: AnyObject!, args: JSON!) -> ()] = []

    init(params: JSON?) {
        self.params = params
        self.invoke = { sender, args -> () in }
        self.invoke = self.getMainEvent()
        self.initEvents()
        self.executionType = .Onece
    }

    private func initEvents() {
        let maxIndex = params!.arrayObject?.count
        for index in 1 ..< maxIndex! {
            self.events.append(TalkEventListener.getListener(index, params: params!))
        }
        self.events.append(self.endTalkEvent)
    }

    private func getMainEvent() -> (sender: AnyObject!, args: JSON!) -> () {
        return {
            (sender: AnyObject!, args: JSON!) -> () in
            if self.events.count > 0 {
                self.events.first!(sender: sender, args: args)
                _ = self.events.removeFirst()
            } else {
                self.delegate!.invoke(self, listener: WalkEventListener(params: self.params))
                self.initEvents()
            }
        }
    }

    private let endTalkEvent: (sender: AnyObject!, args: JSON!) -> () =  {
        sender, args in
        let controller = sender as! GameViewController
        let skView     = controller.view as! SKView
        let scene      = skView.scene as! GameScene
        scene.textBox_.hide()
    }

    static func getListener(index: Int, params: JSON) -> (sender: AnyObject!, args: JSON!) -> () {
        return {
            sender, args in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene
            let map        = scene.map
            let sheet      = map.getSheet()

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