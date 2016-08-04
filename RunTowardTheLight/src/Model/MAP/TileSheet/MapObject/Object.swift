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
    let UP: [[String]]
    let DOWN: [[String]]
    let RIGHT: [[String]]
    let LEFT: [[String]]
}

/// ゲーム画面上に配置されるオブジェクトに対応する，SKSpriteNode のラッパークラス(タイル上ではない)
public class Object: MapObject {
    /// オブジェクト名
    private var name: String!
    
    /// イベント
    internal var events: [EventListener] = []
    
    /// オブジェクトの画像イメージ
    private let images: IMAGE_SET?
    
    /// ノード
    private let object: SKSpriteNode
    
    /// スピード
    private var speed: CGFloat
    
    /// 向き
    private var direction: DIRECTION
    
    /// 画面上の描画位置
    private var position: CGPoint
    
    /// 当たり判定
    internal var hasCollision: Bool
    
    /// 歩行のためのインデックス
    /// 0 のときと 1 のときで左足を出すか右足を出すかかわる．0 と 1 の間で toggle する
    private var stepIndex: Int = 0

    /// 親オブジェクト
    private(set) var parent: MapObject?

    
    init(name: String, position: CGPoint, images: IMAGE_SET?) {
        object = SKSpriteNode()
        object.name = name
        self.name = name
        object.anchorPoint = CGPointMake(0.5, 0.0)
        object.position = position
        speed = 0.2
        direction = DIRECTION.DOWN
        self.hasCollision = false
        self.images = images
        self.position = position
    }

    
    convenience init(name: String, imageName: String, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        object.texture = SKTexture(imageNamed: imageName)
        object.size = CGSize(width: (object.texture?.size().width)!,
                              height: (object.texture?.size().height)!)
    }

    
    convenience init(name: String, imageData: UIImage, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        object.texture = SKTexture(image: imageData)
        object.size = CGSize(width: (object.texture?.size().width)!,
                              height: (object.texture?.size().height)!)
    }
    

    ///  オブジェクトを子ノードとして追加する
    ///
    ///  - parameter node: オブジェクトを追加するノード
    func addTo(node: SKSpriteNode) {
        node.addChild(self.object)
    }
    

    ///  オブジェクトが対象座標へ直線移動するためのアニメーションを返す
    ///  移動時のテクスチャ変更も含めて行う
    ///  TODO: テクスチャ画像も引数として渡せるように変更する
    ///
    ///  - parameter destination: 目標地点
    ///
    ///  - returns: 目標地点へ移動するアニメーション
    func getActionTo(departure: CGPoint, destination: CGPoint) -> Array<SKAction> {
        var actions: Array<SKAction> = []
        let diff = CGPointMake(destination.x - departure.x,
                               destination.y - departure.y)
        var nextTextures: [SKTexture] = []

        if let images = self.images {
            if (diff.x > 0 && diff.y == 0) {
                self.direction = DIRECTION.RIGHT
                nextTextures = []
                for image in images.RIGHT[self.stepIndex] {
                    nextTextures.append(SKTexture(imageNamed: image))
                    self.stepIndex = abs(self.stepIndex-1)
                }
            } else if (diff.x < 0 && diff.y == 0) {
                self.direction = DIRECTION.LEFT
                nextTextures = []
                for image in images.LEFT[self.stepIndex] {
                    nextTextures.append(SKTexture(imageNamed: image))
                    self.stepIndex = abs(self.stepIndex-1)
                }
            } else if (diff.x == 0 && diff.y > 0) {
                self.direction = DIRECTION.UP
                nextTextures = []
                for image in images.UP[self.stepIndex] {
                    nextTextures.append(SKTexture(imageNamed: image))
                    self.stepIndex = abs(self.stepIndex-1)
                }
            } else if (diff.x == 0 && diff.y < 0) {
                self.direction = DIRECTION.DOWN
                nextTextures = []
                for image in images.DOWN[self.stepIndex] {
                    nextTextures.append(SKTexture(imageNamed: image))
                    self.stepIndex = abs(self.stepIndex-1)
                }
            }
        } else {
            nextTextures = [self.object.texture!]
        }

        let walkAction: SKAction = SKAction.animateWithTextures(nextTextures, timePerFrame: NSTimeInterval(self.speed/2))
        let moveAction: SKAction = SKAction.moveByX(diff.x, y: diff.y, duration: NSTimeInterval(self.speed))
        actions = [SKAction.group([walkAction, moveAction])]

        return actions
    }


    ///  連続したアクションを実行する
    ///  アクション実行中は，他のイベントの発生は無視する
    ///  オブジェクトの位置情報の更新も行う
    ///
    ///  - parameter actions:     実行するアクション
    ///  - parameter destination: 最終目的地
    ///  - parameter callback:    実行終了時に呼ばれるコールバック関数ß
    func runAction(actions: Array<SKAction>, destination: CGPoint, callback: () -> Void) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        let sequence: SKAction = SKAction.sequence(actions)
        self.object.runAction(
            sequence,
            completion:
            {
                UIApplication.sharedApplication().endIgnoringInteractionEvents()
                callback()
                // TODO: 現状，最終的な目的地にオブジェクトの位置情報を更新する．リアルタイムに更新できないか？
                self.position = destination
            }
        )
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
            let id = objectPlacement[coordinate]
            if id == nil {
                print("Object ID is not found")
                throw E.error
            }
            let objectID = id!

            // 該当箇所にオブジェクトが存在しない場合，無視
            if objectID == 0 { continue }

            let property = properties[objectID]
            if property == nil {
                print("Object's property not found")
                throw E.error
            }

            let tileSetID = Int(property!["tileSetID"]!)
            if tileSetID == nil {
                print("tileSetID not found")
                throw E.error
            }
            let tileSet = tileSets[tileSetID!]

            let obj_image: UIImage?
            do {
                obj_image = try tileSet?.cropTileImage(objectID)
            } catch {
                print("Failed to crop image for object")
                throw E.error
            }

            let tileSetName = property!["tileSetName"]
            if tileSetName == nil {
                print("tileSetName property is not found")
                throw E.error
            }
            // 一意の名前
            let name = tileSetName! + "_" + NSUUID().UUIDString

            let object = Object(
                name: name,
                imageData: obj_image!,
                position: TileCoordinate.getSheetCoordinateFromTileCoordinate(coordinate),
                images: nil
            )
            objects[coordinate] = [object]

            // 当たり判定の付加
            // TODO: タイルではなくオブジェクトに当たり判定をつける
            if let hasCollision = property!["collision"] {
                if hasCollision == "1" {
                    tiles[coordinate]?.setCollision()
                }
            }

            // イベントの付加
            if let obj_action = property!["event"] {
                // TODO : オブジェクトの切り出しはまとめる
                let tmp = obj_action.componentsSeparatedByString(",")
                let eventType = tmp[0]
                let args = Array(tmp.dropFirst())

                let event = EventListenerGenerator.getListenerByID(eventType, params: args)
                if event == nil {
                    print("eventType is invalid")
                    throw E.error
                }

                // 周囲四方向のタイルにイベントを設置
                // TODO : 各方向に違うイベントが設置できないので修正
                let x = coordinate.getX()
                let y = coordinate.getY()
                tiles[TileCoordinate(x: x - 1, y: y)]?.events.append(event!)
                tiles[TileCoordinate(x: x + 1, y: y)]?.events.append(event!)
                tiles[TileCoordinate(x: x, y: y - 1)]?.events.append(event!)
                tiles[TileCoordinate(x: x, y: y + 1)]?.events.append(event!)
            }
        }
        return objects
    }

    func canPass() -> Bool {
        return !self.hasCollision
    }

    func setCollision() {
        self.hasCollision = true
    }

    func setParent(parent: Object) {
        self.parent = parent
    }
    
    func setEvents(events: [EventListener]) {
        self.events = events
    }
    
    func getEvents() -> [EventListener]? {
        return self.events
    }
    
    func getName() -> String {
        return self.name
    }
    
    func getMovingSpeed() -> CGFloat {
        return self.speed
    }
    
    func getDirection() -> DIRECTION {
        return self.direction
    }
    
    func getPosition() -> CGPoint {
        return self.position
    }
    
    func getRealTimePosition() -> CGPoint {
        return self.object.position
    }
    
    func setZPosition(position: CGFloat) {
        self.object.zPosition = position
    }
}

