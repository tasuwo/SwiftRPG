//
//  TouchEventListener.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON

class ActivateButtonListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType
    var nextListener: EventListener? = nil

    init() {
        self.triggerType = .Immediate
        self.executionType = .Onece
        self.invoke = { (sender: AnyObject!, args: JSON!) -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            scene.actionButton.hidden = false
            self.delegate?.didFinishEvent()
        }
    }
}

class StartTalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType
    var nextListener: EventListener? = nil
    var params: JSON

    init(params: JSON?) {
        self.params = params!
        self.triggerType = .Button
        self.executionType = .Onece
        self.invoke = { (sender: AnyObject!, args: JSON!) -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene
            
            scene.actionButton.hidden = true
            self.delegate?.didFinishEvent()
        }
        self.nextListener = TalkEventListener(params: params)
    }
}

class WalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType
    var nextListener: EventListener? = nil
    var params: JSON?

    init(params: JSON?) {
        self.params = params
        self.triggerType = .Touch
        self.executionType = .Loop
        self.invoke = self.moving
    }

    private let moving = {
        (sender: AnyObject!, args: JSON!) in
        let controller = sender as! GameViewController
        let skView     = controller.view as! SKView
        let scene: GameScene = skView.scene as! GameScene
        let map        = scene.map
        let sheet      = map.getSheet()!

        let touchedPointString = args["touchedPoint"].string
        if touchedPointString == nil {
            print("Invalid arguement")
            return
        }
        let touchedPoint = CGPointFromString(touchedPointString!)
        
        let player = map.getObjectByName(objectNameTable.PLAYER_NAME)!
        let departure   = TileCoordinate.getTileCoordinateFromSheetCoordinate(player.getPosition())
        let destination = TileCoordinate.getTileCoordinateFromScreenCoordinate(sheet.getSheetPosition(), screenCoordinate: touchedPoint)

        // ルート探索
        let aStar = AStar(map: map)
        aStar.initialize(departure, destination: destination)
        let path = aStar.main()
        if path == nil { return }

        // 移動のためのアクションの定義
        var playerActions: Array<SKAction> = []
        var events: [EventListener] = []
        for step: TileCoordinate in path! {
            let stepPoint: CGPoint = TileCoordinate.getSheetCoordinateFromTileCoordinate(step)
            playerActions += player.getActionTo(stepPoint)

            // 移動中にイベントが存在するタイルを踏んだら動きを止める
            let eventsOnStep = map.getEventsOn(step)
            if eventsOnStep.count > 0 {
                events = eventsOnStep
                break
            }
        }

        // 画面をスクロールさせる
        let delay = SKAction.waitForDuration(NSTimeInterval(Double(player.getMovingSpeed() * CGFloat(path!.count))))
        let scrollAction: SKAction? = sheet.scrollSheet(destination)
        var scrollActions: Array<SKAction> = []
        if scrollAction != nil {
            scrollActions.append(delay)
            scrollActions.append(scrollAction!)
        }

        scene.movePlayer(playerActions, events: events, screenActions: scrollActions)
    }
}

class TalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType = .Touch
    private(set) var executionType: ExecutionType = .Loop
    var nextListener: EventListener? = nil
    var params: JSON?
    var events: [(sender: AnyObject!, args: JSON!) -> ()] = []

    init(params: JSON?) {
        self.params = params

        self.invoke = {
            sender, args -> () in
        }
        self.invoke = self.getMainEvent()

        self.initEvents()

        self.executionType = .Onece
    }

    private func initEvents() {
        // イベント生成
        let maxIndex = params!.arrayObject?.count
        for index in 0 ..< maxIndex! {
            self.events.append(TalkEventListener.getTalkingEvent(index, params: params!))
        }
        self.events.append(self.endTalkEvent)
        self.nextListener = WalkEventListener(params: nil)
    }

    private func getMainEvent() -> (sender: AnyObject!, args: JSON!) -> () {
        return {
            (sender: AnyObject!, args: JSON!) -> () in
            if self.events.count > 0 {
                self.events.first!(sender: sender, args: args)
                _ = self.events.removeFirst()
            } else {
                self.delegate!.didFinishEvent()
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

    private static func getTalkingEvent(index: Int, params: JSON) -> (sender: AnyObject!, args: JSON!) -> () {
        return {
            sender, args in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene
            let map        = scene.map
            let sheet      = map.getSheet()

            // params の検査
            let talker: String
            let talkBody: String
            let talkSide: Dialog.TALK_SIDE
            if  let _character = params[index]["talker"].string,
                let _body      = params[index]["talk_body"].string,
                let _talk_side = params[index]["talk_side"].string,
                let _talker    = TALKER_IMAGE[_character]
            {
                talker = _talker
                talkBody = _body
                switch _talk_side {
                case "L": talkSide = Dialog.TALK_SIDE.left
                case "R": talkSide = Dialog.TALK_SIDE.right
                default: print("Invalid json param for talking"); return
                }
            } else {
                print(params)
                print("Invalid json param for talking")
                return
            }

            // ボタンを隠す
            scene.actionButton.hidden = true

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
            scene.textBox_.drawText(talker, body: talkBody, side: talkSide)
        }
    }
}
