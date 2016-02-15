//
//  GameSceneEvent.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/09/28.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import SpriteKit
import SwiftyJSON

// params の形式は守る必要が有る
// TODO: param の validation. いつか必ずつまづく
// TODO: 各イベントにコールバックをもたせて，同期的に連続で実行できるようにしたい

class GameSceneEvent: NSObject {
    static var events: Dictionary<String, (JSON?) -> EventListener<AnyObject?>> =
    [
            // params: String
            // タッチイベントの入れ替えが必要
            // スタック構造にして前入れておいた要素が消えないようにしたほうが良いかもね
            "talk": {
                params in
                return EventListener<AnyObject?>() {
                    sender, args in
                    let controller = sender as! GameViewController
                    let skView = controller.view as! SKView
                    let scene = skView.scene as! GameScene
                    let sheet = scene.sheet

                    scene.actionButton_.hidden = true

                    // キャラとかぶらないように
                    let playerPosition = sheet.getObjectPosition("tasuwo")
                    var position: Dialog.POSITION!
                    if playerPosition.y <= scene.frame.height / 2 {
                        position = Dialog.POSITION.top
                    } else {
                        position = Dialog.POSITION.bottom
                    }
                    // -- for debug
                    position = Dialog.POSITION.bottom
                    // --
                    scene.textBox_.show(position)
                    scene.textBox_.drawText(params!.string!, talkSide: Dialog.TALK_SIDE.right)

                    controller.touchEvent.remove(controller.movePlayer_)
                    controller.touchEvent.add(GameSceneEvent.touchEvents["wait"]!(nil))
                }
            },
            "move": {
                params in
                return EventListener<AnyObject?>() {
                    sender, args in
                    let controller = sender as! GameViewController
                    let skView = controller.view as! SKView
                    let scene = skView.scene as! GameScene
                    let sheet = scene.sheet
                    scene.actionButton_.hidden = true

                    let departure = sheet.getObjectTileCoordinateBy("tasuwo")
                    let destination = TileCoordinate(x: (departure?.getX())! - 1,
                                                     y: (departure?.getY())! - 1)
                    let a_star = AStar(sheet: sheet)
                    a_star.initialize(departure!, destination: destination)
                    let path = a_star.main()

                    if (path != nil) {
                        var actions: Array<SKAction> = []
                        for step in path! {
                            actions += sheet.getActionTo("tasuwo", to: step)
                        }
                        sheet.moveObject("tasuwo", actions: actions, callback: {})
                    }
                }
            },
            // params: ボタンのラベル, ラベル押下時のイベント
            "ready_action": {
                params in
                return EventListener<AnyObject?>() {
                    sender, args in
                    let controller = sender as! GameViewController
                    let skView = controller.view as! SKView
                    let scene = skView.scene as! GameScene
                    let sheet = scene.sheet

                    scene.actionButton_.hidden = false
                    // ボタンのアクション設定
                    let json: JSON? = "・・・・・。"
                    controller.actionEvent.add(
                    GameSceneEvent.events["talk"]!(json)
                    )
                }
            }
    ]
    static var touchEvents: Dictionary<String, (JSON?) -> EventListener<CGPoint>> =
    [
            // 普段の移動
            "common_moving": {
                params in
                return EventListener<CGPoint>() {
                    sender, args in
                    let controller = sender as! GameViewController
                    let skView = controller.view as! SKView
                    let scene = skView.scene as! GameScene
                    let sheet = scene.sheet
                    scene.textBox_.hide()
                    scene.actionButton_.hidden = true

                    // detect frame
                    if sheet.isOnFrame(args) {
                        return
                    }

                    // route search
                    let departure = sheet.getObjectTileCoordinateBy("tasuwo")
                    let destination = sheet.getTileCoordinateNear(args)
                    let aStar = AStar(sheet: sheet)
                    aStar.initialize(departure!, destination: destination)
                    let path = aStar.main()

                    // move object
                    var event: EventDispatcher<AnyObject?>?
                    if (path != nil) {
                        // get action per step
                        var actions: Array<SKAction> = []
                        for step in path! {
                            actions += sheet.getActionTo("tasuwo", to: step)
                            event = sheet.isEventOn(step)
                            if (event != nil) {
                                break
                            }
                        }

                        // animation
                        sheet.moveObject(
                        "tasuwo",
                        actions: actions,
                        callback: {
                            event?.trigger(controller, args: nil)
                        }
                        )

                        // detect scroll
                        let scrollAction = sheet.detectScroll(destination)
                        if (scrollAction != nil) {
                            let delay = SKAction.waitForDuration(
                            NSTimeInterval(
                            Double(sheet.getPlayerSpeed("tasuwo") * CGFloat((path?.count)!)))
                            )
                            var actions: Array<SKAction> = []
                            actions.append(delay)
                            actions.append(scrollAction!)

                            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                            sheet.runAction(actions, callback: {
                                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                            })
                        }
                    }
                }
            },
            // ダイアログを消してるので，ダイアログ用のボタン押下待ちのイベントにしたほうが良いかも
            "wait": {
                params in
                return EventListener<CGPoint>() {
                    sender, args in
                    let controller = sender as! GameViewController
                    let skView = controller.view as! SKView
                    let scene = skView.scene as! GameScene
                    let sheet = scene.sheet
                    scene.textBox_.hide()

                    controller.touchEvent.remove(GameSceneEvent.touchEvents["wait"]!(nil))
                    controller.touchEvent.add(controller.movePlayer_)
                }
            }
    ]
}