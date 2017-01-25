//
//  Tile.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/08/03.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

typealias TileID = Int
typealias TileSetID = Int
typealias TileProperty = Dictionary<String, String>

/// マップ上に敷かれる各タイルに対応した SKSpriteNode のラッパークラス
open class Tile: MapObject {
    static var           TILE_SIZE: CGFloat = 32.0
    fileprivate let      tileId: Int
    fileprivate let      node: SKSpriteNode
    fileprivate(set) var coordinate: TileCoordinate
    fileprivate(set) var property: TileProperty

    // MARK: - MapObject

    fileprivate(set) var id: MapObjectId
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
    static var nextId = 0
    static func generateId() -> MapObjectId {
        nextId += 1
        return nextId
    }

    // MARK: -

    ///  コンストラクタ
    ///
    ///  - parameter coordinate: タイルの座標
    ///  - parameter event:      タイルに配置するイベント
    ///
    ///  - returns: なし
    init(id: TileID, coordinate: TileCoordinate, property: TileProperty) {
        self.id = Tile.generateId()
        let x = coordinate.x
        let y = coordinate.y
        self.tileId = id
        self.node = SKSpriteNode()
        self.node.size = CGSize(width: CGFloat(Tile.TILE_SIZE),
                                height: CGFloat(Tile.TILE_SIZE))
        self.node.position = CGPoint(x: CGFloat(x - 1) * Tile.TILE_SIZE,
                                     y: CGFloat(y - 1) * Tile.TILE_SIZE)
        self.node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        self.node.zPosition = zPositionTable.TILE
        self.coordinate = TileCoordinate(x: x, y: y)
        self.hasCollision = false
        self.property = property
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter imageName: 付加するテクスチャ画像名
    func setImageWithName(_ imageName: String) {
        node.texture = SKTexture(imageNamed: imageName)
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter image: 付加するテクスチャ画像
    func setImageWithUIImage(_ image: UIImage) {
        node.texture = SKTexture(image: image)
    }

    ///  タイルのノードに子ノードを追加する
    ///
    ///  - parameter node: 追加する子ノード
    func addTo(_ node: SKSpriteNode) {
        node.addChild(self.node)
    }

    func removeCollision() {
        self.hasCollision = false
    }

    // MARK: - class method

    ///  タイル群を生成する
    ///
    ///  - parameter rows:               タイルを敷き詰める列数
    ///  - parameter cols:               タイルを敷き詰める行数
    ///  - parameter properties:         タイル及びオブジェクトのプロパティ
    ///  - parameter tileSets:           タイルセットの情報
    ///  - parameter collisionPlacement: マップにおける当たり判定の配置
    ///  - parameter tilePlacement:      マップにおけるタイルの配置
    ///
    ///  - throws:
    ///
    ///  - returns: 生成したタイル群
    class func createTiles(
        _ rows: Int,
        cols: Int,
        properties: Dictionary<TileID, TileProperty>,
        tileSets: Dictionary<TileSetID, TileSet>,
        collisionPlacement: Dictionary<TileCoordinate, Int>,
        tilePlacement: Dictionary<TileCoordinate, Int>
    ) throws -> Dictionary<TileCoordinate, Tile> {
        var tiles: Dictionary<TileCoordinate, Tile> = [:]
        for (coordinate, tileID) in tilePlacement {
            let tileProperty = properties[tileID]
            if tileProperty == nil {
                throw MapObjectError.failedToGenerate("tileID \(tileID.description)'s property is not defined in properties(\(properties.description))")
            }

            // タイルを作成する
            let tile = Tile(
                id: tileID,
                coordinate: coordinate,
                property: tileProperty!
            )

            // 当たり判定を付加する
            let hasCollision = collisionPlacement[coordinate]
            if hasCollision == nil {
                throw MapObjectError.failedToGenerate("Coordinate(\(coordinate.description)) specified in tilePlacement is not defined at collisionPlacement(\(collisionPlacement.description))")
            }
            if hasCollision != 0 {
                tile.setCollision()
            }

            // 画像を付与する
            let tileSetID = Int(tile.property["tileSetID"]!)
            if tileSetID == nil {
                throw MapObjectError.failedToGenerate("tileSetID is not defined in tile \(tile)'s property(\(tile.property.description))")
            }

            let tileSet = tileSets[tileSetID!]
            if tileSet == nil {
                throw MapObjectError.failedToGenerate("tileSet(ID = \(tileSetID?.description)) is not defined in tileSets(\(tileSets.description))")
            }

            let tileImage: UIImage?
            do {
                tileImage = try tileSet!.cropTileImage(tileID)
            } catch {
                throw MapObjectError.failedToGenerate("Failed to crop image of object which tileID is \(tileID)")
            }
            tile.setImageWithUIImage(tileImage!)

            // イベントを付与する
            if let action = tile.property["event"] {
                let listeners: Dictionary<TileCoordinate, EventListener>
                do {
                    let properties = try EventPropertyParser.parse(from: action)
                    listeners = try ListenerGenerator.generate(properties: properties)
                } catch EventParserError.invalidProperty(let string) {
                    throw MapObjectError.failedToGenerate("Failed to generate event listener: " + string)
                } catch ListenerGeneratorError.failed(let string) {
                    throw MapObjectError.failedToGenerate("Failed to generate event listener: " + string)
                }

                if listeners.count > 1 {
                    throw MapObjectError.failedToGenerate("Tile event should has only one relative coordinate")
                }
                if listeners.count == 1 && listeners.first?.key != TileCoordinate(x:0,y:0) {
                    throw MapObjectError.failedToGenerate("Tile event should has (0,0) relative coordinate")
                }

                tile.events.append(listeners.first!.value)
            }

            tiles[coordinate] = tile
        }
        return tiles
    }

    // MARK: -
}
