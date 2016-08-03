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

class WalkEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType
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


