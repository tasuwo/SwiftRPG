//
//  Object.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/08/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

/// ゲーム画面上に配置されるオブジェクトに対応する，SKSpriteNode のラッパークラス(タイル上ではない)
open class Object: MapObject {
    fileprivate let      images: IMAGE_SET?
    fileprivate(set) var speed: CGFloat
    fileprivate(set) var direction: DIRECTION
    fileprivate let      node: SKSpriteNode
    var name: String! {
        get {
            return self.node.name
        }
    }
    var position: CGPoint {
        get {
            return self.node.position
        }
    }
    var coordinate: TileCoordinate {
        get {
            return TileCoordinate.getTileCoordinateFromSheetCoordinate(self.position)
        }
    }
    /// Index for animation
    /// Whether the step animation is started from left or right leg is depends on whether this value is 1 or 0.
    fileprivate var stepIndex: Int = 0
    var children: [MapObject] = []

    // MARK: - MapObject

    fileprivate(set) var hasCollision: Bool
    fileprivate var events_: [EventListener] = []
    var events: [EventListener] {
        get {
            return self.events_
        }
        set {
            self.events_ = newValue
        }
    }
    fileprivate var parent_: MapObject?
    var parent: MapObject? {
        get {
            return self.parent_
        }
        set {
            self.parent_ = newValue
        }
    }
    func setCollision() {
        self.hasCollision = true
    }

    // MARK: -

    init(name: String, position: CGPoint, images: IMAGE_SET?) {
        node = SKSpriteNode()
        node.name = name
        node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        node.position = position
        speed = 0.2
        direction = DIRECTION.down
        self.hasCollision = false
        self.images = images
    }

    convenience init(name: String, imageName: String, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        node.texture = SKTexture(imageNamed: imageName)
        node.size = CGSize(width: (node.texture?.size().width)!,
                              height: (node.texture?.size().height)!)
    }

    convenience init(name: String, imageData: UIImage, position: CGPoint, images: IMAGE_SET?) {
        self.init(name: name, position: position, images: images)
        node.texture = SKTexture(image: imageData)
        node.size = CGSize(width: (node.texture?.size().width)!,
                              height: (node.texture?.size().height)!)
    }

    ///  Add object as a child
    ///
    ///  - parameter node: Object which is added
    func addTo(_ node: SKSpriteNode) {
        node.addChild(self.node)
    }

    ///  オブジェクトが対象座標へ直線移動するためのアニメーションを返す
    ///  移動時のテクスチャ変更も含めて行う
    ///  TODO: テクスチャ画像も引数として渡せるように変更する
    ///
    ///  - parameter destination: 目標地点
    ///
    ///  - returns: 目標地点へ移動するアニメーション
    func getActionTo(_ departure: CGPoint, destination: CGPoint) -> Array<SKAction> {
        var actions: Array<SKAction> = []
        let diff = CGPoint(x: destination.x - departure.x,
                           y: destination.y - departure.y)
        var nextTextures: [SKTexture] = []

        if let images = self.images {
            let direction = self.calcDirection(departure: departure, destination: destination)
            for image in images.get(direction)[self.stepIndex] {
                nextTextures.append(SKTexture(imageNamed: image))
                self.stepIndex = abs(self.stepIndex-1)
            }
        } else {
            nextTextures = [self.node.texture!]
        }

        let walkAction: SKAction = SKAction.animate(with: nextTextures, timePerFrame: TimeInterval(self.speed/2))
        let moveAction: SKAction = SKAction.moveBy(x: diff.x, y: diff.y, duration: TimeInterval(self.speed))
        actions = [SKAction.group([walkAction, moveAction])]

        return actions
    }

    fileprivate func calcDirection(departure: CGPoint, destination: CGPoint) -> DIRECTION {
        let diff = CGPoint(x: destination.x - departure.x,
                           y: destination.y - departure.y)
        // There are a little deviation between tile coordinate's position and SKSpriteNode position.
        // So the difference of position between object on tile and the tile isn't be 0 sometime e.g. 0.000015...
        // This value is used for resolve this deviation.
        let t: CGFloat = 0.1
        let inThreshold = {
            (v: CGFloat, t: CGFloat) -> Bool in
            return (-1 * t <= v && v <= t)
        }

        if (diff.x > 0 && inThreshold(diff.y, t)) {
            return .right
        } else if (diff.x < 0 && inThreshold(diff.y, t)) {
            return .left
        } else if (inThreshold(diff.x, t) && diff.y > 0) {
            return .up
        } else if (inThreshold(diff.x, t) && diff.y < 0) {
            return .down
        } else {
            // TODO: Shold throw exception?
            return .down
        }
    }

    ///  連続したアクションを実行する
    ///  アクション実行中は，他のイベントの発生は無視する
    ///  オブジェクトの位置情報の更新も行う
    ///
    ///  - parameter actions:     実行するアクション
    ///  - parameter destination: 最終目的地
    ///  - parameter callback:    実行終了時に呼ばれるコールバック関数ß
    func runAction(_ actions: Array<SKAction>, destination: CGPoint, callback: @escaping () -> Void) {
        UIApplication.shared.beginIgnoringInteractionEvents()
        let sequence: SKAction = SKAction.sequence(actions)
        self.node.run(
            sequence,
            completion:
            {
                UIApplication.shared.endIgnoringInteractionEvents()
                callback()
                // TODO: 現状，最終的な目的地にオブジェクトの位置情報を更新する．リアルタイムに更新できないか？
                // self.position = destination
            }
        )
    }

    ///  オブジェクトの方向を指定する．
    ///  画像が存在すれば，方向に応じて適切な画像に切り替える．
    ///
    ///  - parameter direction: オブジェクトの向く方向
    func setDirection(_ direction: DIRECTION) {
        self.direction = direction
        if let images = self.images {
            let imageNames = images.get(direction)
            self.node.texture = SKTexture(imageNamed: imageNames[0][1])
        }
    }

    ///  オブジェクトの Z 軸方向の位置を指定する．
    ///
    ///  - parameter position: z軸方向の位置
    func setZPosition(_ position: CGFloat) {
        self.node.zPosition = position
    }

    // MARK: - class method

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
        _ tiles: Dictionary<TileCoordinate, Tile>,
        properties: Dictionary<TileID, TileProperty>,
        tileSets: Dictionary<TileSetID, TileSet>,
        objectPlacement: Dictionary<TileCoordinate, Int>
    ) throws -> Dictionary<TileCoordinate, [Object]> {
        var objects: Dictionary<TileCoordinate, [Object]> = [:]
        for (coordinate, _) in tiles {
            objects[coordinate] = []
        }

        // オブジェクトの配置
        for (coordinate, _) in tiles {
            let id = objectPlacement[coordinate]
            if id == nil {
                throw MapObjectError.failedToGenerate("Coordinate(\(coordinate.description)) specified in tiles is not defined at objectPlacement")
            }
            let objectID = id!

            // 該当箇所にオブジェクトが存在しない場合，無視
            if objectID == 0 { continue }

            let property = properties[objectID]
            if property == nil {
                throw MapObjectError.failedToGenerate("ObjectID \(objectID.description)'s property is not defined in properties")
            }

            let tileSetID = Int(property!["tileSetID"]!)
            if tileSetID == nil {
                throw MapObjectError.failedToGenerate("tileSetID is not defined in objectID \(objectID.description)'s property(\(property?.description))")
            }

            let tileSet = tileSets[tileSetID!]
            if tileSet == nil {
                throw MapObjectError.failedToGenerate("tileSet(ID = \(tileSetID?.description)) is not defined in tileSets(\(tileSets.description))")
            }

            let obj_image: UIImage?
            do {
                obj_image = try tileSet?.cropTileImage(objectID)
            } catch {
                throw MapObjectError.failedToGenerate("Failed to crop image of object which objectID is \(objectID.description)")
            }

            let tileSetName = property!["tileSetName"]
            if tileSetName == nil {
                throw MapObjectError.failedToGenerate("tileSetName is not defined in objectID \(objectID.description)'s property(\(property?.description))")
            }

            // TODO: Resolve name duplication
            let object = Object(
                name: tileSetName!,
                imageData: obj_image!,
                position: TileCoordinate.getSheetCoordinateFromTileCoordinate(coordinate),
                images: nil
            )

            // 当たり判定の付加
            if let hasCollision = property!["collision"] {
                if hasCollision == "1" {
                    object.setCollision()
                }
            }

            // イベントの付加
            if let obj_action = property!["event"] {
                do {
                    let properties = try EventPropertyParser.parse(from: obj_action)
                    let listeners = try ListenerGenerator.generate(properties: properties)

                    var eventObjects: [Object] = []
                    let parent = object

                    // Create event object for per coordinate
                    for (coordinate, listener) in listeners {
                        // TODO: Give a name
                        let eventObject: Object = Object(
                            name: "",
                            position: TileCoordinate.getSheetCoordinateFromTileCoordinate(parent.coordinate + coordinate),
                            images: nil)

                        eventObject.events.append(listener)

                        object.children.append(eventObject)
                        eventObject.parent = parent
                        eventObjects.append(eventObject)
                    }

                    // Placement event objects on object dict map
                    for eventObject in eventObjects {
                        objects[eventObject.coordinate]!.append(eventObject)
                    }
                } catch EventParserError.invalidProperty(let string) {
                    throw MapObjectError.failedToGenerate("Failed to generate event listener: " + string)
                } catch ListenerGeneratorError.failed(let string) {
                    throw MapObjectError.failedToGenerate("Failed to generate event listener: " + string)
                }
            }

            objects[coordinate]!.append(object)
        }
        return objects
    }

    // MARK: -
}

