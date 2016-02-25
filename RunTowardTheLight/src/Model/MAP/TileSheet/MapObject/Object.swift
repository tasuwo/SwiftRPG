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

struct IMAGE_SET {
    let UP: String
    let DOWN: String
    let RIGHT: String
    let LEFT: String
}

/// ゲーム画面上に配置されるオブジェクトに対応する，SKSpriteNode のラッパークラス(タイル上ではない)
public class Object: MapObject {
    /// オブジェクト名
    private var name_: String!
    
    /// イベント
    internal var event: EventDispatcher<Any>?
    
    /// オブジェクトの画像イメージ
    private let images_: IMAGE_SET?
    
    /// ノード
    private let object_: SKSpriteNode
    
    /// スピード
    private var speed_: CGFloat
    
    /// 向き
    private var direction_: DIRECTION
    
    /// 画面上の描画位置
    private var position_: CGPoint
    
    /// 当たり判定
    internal var hasCollision: Bool

    
    init(name: String, position: CGPoint, images: IMAGE_SET?) {
        object_ = SKSpriteNode()
        object_.name = name
        self.name_ = name
        object_.anchorPoint = CGPointMake(0.5, 0.0)
        object_.position = position
        speed_ = 0.2
        direction_ = DIRECTION.DOWN
        self.hasCollision = false
        self.images_ = images
        position_ = position
    }

    
    convenience init(name: String, imageName: String, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        object_.texture = SKTexture(imageNamed: imageName)
        object_.size = CGSize(width: (object_.texture?.size().width)!,
                              height: (object_.texture?.size().height)!)
    }

    
    convenience init(name: String, imageData: UIImage, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        object_.texture = SKTexture(image: imageData)
        object_.size = CGSize(width: (object_.texture?.size().width)!,
                              height: (object_.texture?.size().height)!)
    }
    

    ///  オブジェクトを子ノードとして追加する
    ///
    ///  - parameter node: オブジェクトを追加するノード
    func addTo(node: SKSpriteNode) {
        node.addChild(self.object_)
    }
    

    ///  オブジェクトが対象座標へ直線移動するためのアニメーションを返す
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
        var nextTexture: SKTexture?

        if let images = self.images_ {
            if (diff.x > 0 && diff.y == 0) {
                direction_ = DIRECTION.RIGHT
                nextTexture = SKTexture(imageNamed: images.RIGHT)
            } else if (diff.x < 0 && diff.y == 0) {
                direction_ = DIRECTION.LEFT
                nextTexture = SKTexture(imageNamed: images.LEFT)
            } else if (diff.x == 0 && diff.y > 0) {
                direction_ = DIRECTION.UP
                nextTexture = SKTexture(imageNamed: images.UP)
            } else if (diff.x == 0 && diff.y < 0) {
                direction_ = DIRECTION.DOWN
                nextTexture = SKTexture(imageNamed: images.DOWN)
            }
        } else {
            nextTexture = self.object_.texture
        }

        if let texture = nextTexture {
            actions.append(SKAction.animateWithTextures([texture],
                           timePerFrame: NSTimeInterval(0.0)))
        }
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
        object_.runAction(
            sequence,
            completion: {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                
                callback()
        })
    }
    
    
    ///  オブジェクトを生成する
    ///
    ///  - parameter tiles:           生成済みのタイル群．本メソッド内で内容を書き換えられる可能性有り．
    ///  - parameter properties:      タイル及びオブジェクトのプロパティ群
    ///  - parameter tileSets:        タイルセットの情報
    ///  - parameter objectPlacement: オブジェクトの配置情報
    ///
    ///  - throws:
    ///
    ///  - returns: 生成したオブジェクト群
    class func createObjects(
        tiles: Dictionary<TileCoordinate, Tile>,
        properties: Dictionary<TileID, TileProperty>,
        tileSets: Dictionary<TileSetID, TileSet>,
        objectPlacement: Dictionary<TileCoordinate, Int>
    ) throws -> Dictionary<TileCoordinate, [Object]> {
        var objects: Dictionary<TileCoordinate, [Object]> = [:]
        
        // オブジェクトの配置
        for (coordinate, _) in tiles {
            let objectID: Int
            if let id = objectPlacement[coordinate] {
                objectID = id
            } else {
                // TODO : 真面目にエラーハンドリングする
                print("オブジェクトのID取得失敗")
                throw E.error
            }
            
            if objectID != 0 {
                let property = properties[objectID]
                
                // オブジェクトの生成
                let tileSetID = Int(property!["tileSetID"]!)
                do {
                    let tileSet = tileSets[tileSetID!]
                    let obj_image = try tileSet?.cropTileImage(objectID)
                    let name = property!["tileSetName"]! + "_" + NSUUID().UUIDString
                    objects[coordinate] = [Object(
                        name: name, /* 一意の名前をつける */
                        imageData: obj_image!,
                        position: TileCoordinate.getSheetCoordinateFromTileCoordinate(coordinate),
                        images: nil
                    )]
                } catch {
                    print("object生成失敗")
                    throw E.error
                }
                
                // 当たり判定の付加
                // TODO: タイルではなくオブジェクトに当たり判定をつける
                if let hasCollision = property!["collision"] {
                    if hasCollision == "1" {
                        tiles[coordinate]?.setCollision()
                    }
                }
                
                // イベントの付加
                if let obj_action = property!["event"] {
                    let events = EventDispatcher<Any>()
                    events.add(GameSceneEvent.events[obj_action]!(nil))
                    // 周囲四方向のタイルにイベントを設置
                    // TODO : 各方向に違うイベントが設置できないので修正
                    let x = coordinate.getX()
                    let y = coordinate.getY()
                    tiles[TileCoordinate(x: x - 1, y: y)]?.event = events
                    tiles[TileCoordinate(x: x + 1, y: y)]?.event = events
                    tiles[TileCoordinate(x: x, y: y - 1)]?.event = events
                    tiles[TileCoordinate(x: x, y: y + 1)]?.event = events
                }
            }
        }
        
        return objects
    }
    
    func canPass() -> Bool {
        return !hasCollision
    }
    
    func setCollision() {
        hasCollision = true
    }
    
    func setEvent(event: EventDispatcher<Any>) {
        self.event = event
    }
    
    func getEvent() -> EventDispatcher<Any>? {
        return self.event
    }
    
    func getName() -> String {
        return self.name_
    }
    
    func getMovingSpeed() -> CGFloat {
        return speed_
    }
    
    func getDirection() -> DIRECTION {
        return direction_
    }
    
    func getPosition() -> CGPoint {
        return self.position_
    }
    
    func getRealTimePosition() -> CGPoint {
        return self.object_.position
    }
    
    func setZPosition(position: CGFloat) {
        self.object_.zPosition = position
    }
}

