//
//  Object.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/08/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

/// ゲーム画面上に配置されるオブジェクト
class Object {
    private let object_: SKSpriteNode
    private var speed_: CGFloat
    private var position_: CGPoint
    private var direction_: TileSheet.DIRECTION

    init(name: String, position: CGPoint) {
        object_ = SKSpriteNode()
        object_.name = name
        object_.anchorPoint = CGPointMake(0.5, 0.0)
        object_.position = position
        position_ = position

        speed_ = 0.2

        direction_ = TileSheet.DIRECTION.DOWN
    }

    convenience init(name: String, imageName: String, position: CGPoint) {
        self.init(name: name, position: position)
        object_.texture = SKTexture(imageNamed: imageName)
        object_.size = CGSize(width: (object_.texture?.size().width)!,
                              height: (object_.texture?.size().height)!)
    }

    convenience init(name: String, imageData: UIImage, position: CGPoint) {
        self.init(name: name, position: position)
        object_.texture = SKTexture(image: imageData)
        object_.size = CGSize(width: (object_.texture?.size().width)!,
                              height: (object_.texture?.size().height)!)
    }

    func getMovingSpeed() -> CGFloat {
        return speed_
    }

    func getDirection() -> TileSheet.DIRECTION {
        return direction_
    }

    func getPosition() -> CGPoint {
        return object_.position
    }

    func addTo(node: SKSpriteNode) {
        node.addChild(object_)
    }

    ///  目的地が対象座標へ直線移動するためのアニメーションを返す
    ///  移動時のテクスチャ変更も含めて行う
    ///  TODO: テクスチャ画像も引数として渡せるように変更する
    ///
    ///  - parameter destination: 目標地点
    ///
    ///  - returns: 目標地点へ移動するアニメーション
    func getActionTo(destination: CGPoint) -> Array<SKAction> {
        var actions: Array<SKAction> = []
        let position = position_

        let diff = CGPointMake(destination.x - position.x,
                               destination.y - position.y)

        var nextTexture: SKTexture!

        // 方向の決定
        // TODO: プレイヤー画像以外にも対応
        // 画像をjsonとかで渡せるといいなぁ
        if (diff.x > 0 && diff.y == 0) {
            direction_ = TileSheet.DIRECTION.RIGHT
            nextTexture = SKTexture(imageNamed: "plr_right.png")
        } else if (diff.x < 0 && diff.y == 0) {
            direction_ = TileSheet.DIRECTION.LEFT
            nextTexture = SKTexture(imageNamed: "plr_left.png")
        } else if (diff.x == 0 && diff.y > 0) {
            direction_ = TileSheet.DIRECTION.UP
            nextTexture = SKTexture(imageNamed: "plr_up.png")
        } else if (diff.x == 0 && diff.y < 0) {
            direction_ = TileSheet.DIRECTION.DOWN
            nextTexture = SKTexture(imageNamed: "plr_down.png")
        }

        actions.append(SKAction.animateWithTextures([nextTexture],
                                                    timePerFrame: NSTimeInterval(0.0)))
        actions.append(SKAction.moveByX(diff.x,
                                        y: diff.y,
                                        duration: NSTimeInterval(speed_)))
        position_ = CGPointMake(destination.x,
                                destination.y)
        return actions
    }

    ///  連続したアクションを実行する
    ///  アクション実行中は，他のイベントの発生は無視する
    ///
    ///  - parameter actions:  実行するアクション
    ///  - parameter callback: 実行終了時に呼ばれるコールバック関数ß
    func runAction(actions: Array<SKAction>, callback: () -> Void) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let sequence: SKAction = SKAction.sequence(actions)
        object_.runAction(sequence,
                          completion: {
                              UIApplication.sharedApplication().endIgnoringInteractionEvents()
                              callback()
                          })
    }
}

