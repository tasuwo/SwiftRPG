//
//  Tile.swift
//  RunTowardTheLight
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
public class Tile: MapObject {
    /// タイルID
    private let tileID: Int

    /// ノード
    private let tile: SKSpriteNode

    /// サイズ
    static var TILE_SIZE: CGFloat = 32.0

    /// 座標
    private(set) var coordinate: TileCoordinate

    /// プロパティ
    private(set) var property: TileProperty

    // MARK: - MapObject

    private(set) var hasCollision: Bool

    private var events_: [EventListener] = []
    var events: [EventListener] {
        get {
            return self.events_
        }
        set {
            self.events_ = newValue
        }
    }

    private var parent_: MapObject?
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

    ///  コンストラクタ
    ///
    ///  - parameter coordinate: タイルの座標
    ///  - parameter event:      タイルに配置するイベント
    ///
    ///  - returns: なし
    init(id: TileID, coordinate: TileCoordinate, property: TileProperty) {
        let x = coordinate.x
        let y = coordinate.y
        self.tileID = id
        self.tile = SKSpriteNode()
        self.tile.size = CGSizeMake(CGFloat(Tile.TILE_SIZE),
                                     CGFloat(Tile.TILE_SIZE))
        self.tile.position = CGPointMake(CGFloat(x - 1) * Tile.TILE_SIZE,
                                          CGFloat(y - 1) * Tile.TILE_SIZE)
        self.tile.anchorPoint = CGPointMake(0.0, 0.0)
        self.tile.zPosition = zPositionTable.TILE
        self.coordinate = TileCoordinate(x: x, y: y)
        self.hasCollision = false
        self.property = property
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter imageName: 付加するテクスチャ画像名
    func setImageWithName(imageName: String) {
        tile.texture = SKTexture(imageNamed: imageName)
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter image: 付加するテクスチャ画像
    func setImageWithUIImage(image: UIImage) {
        tile.texture = SKTexture(image: image)
    }

    ///  タイルのノードに子ノードを追加する
    ///
    ///  - parameter node: 追加する子ノード
    func addTo(node: SKSpriteNode) {
        node.addChild(self.tile)
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
        rows: Int,
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
                throw MapObjectError.FailedToGenerate("tileID \(tileID.description)'s property is not defined in properties(\(properties.description))")
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
                throw MapObjectError.FailedToGenerate("Coordinate(\(coordinate.description)) specified in tilePlacement is not defined at collisionPlacement(\(collisionPlacement.description))")
            }
            if hasCollision != 0 {
                tile.setCollision()
            }

            // 画像を付与する
            let tileSetID = Int(tile.property["tileSetID"]!)
            if tileSetID == nil {
                throw MapObjectError.FailedToGenerate("tileSetID is not defined in tile \(tile)'s property(\(tile.property.description))")
            }

            let tileSet = tileSets[tileSetID!]
            if tileSet == nil {
                throw MapObjectError.FailedToGenerate("tileSet(ID = \(tileSetID?.description)) is not defined in tileSets(\(tileSets.description))")
            }

            let tileImage: UIImage?
            do {
                tileImage = try tileSet!.cropTileImage(tileID)
            } catch {
                throw MapObjectError.FailedToGenerate("Failed to crop image of object which tileID is \(tileID)")
            }
            tile.setImageWithUIImage(tileImage!)

            // イベントを付与する
            if let action = tile.property["event"] {
                // TODO : イベントの切り出しはまとめる
                let tmp = action.componentsSeparatedByString(",")
                let eventType = tmp[0]
                let args = Array(tmp.dropFirst())

                let event: EventListener
                let eventListenerErrorMessage = "Error occured at the time of generating event listener: "
                do {
                    event = try EventListenerGenerator.getListenerByID(eventType, directionToParent: nil, params: args)
                } catch EventListenerError.IllegalArguementFormat(let string) {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + string)
                } catch EventListenerError.IllegalParamFormat(let string) {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + string)
                } catch EventListenerError.InvalidParam(let string) {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + string)
                } catch EventListenerError.ParamIsNil {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + "Required param is nil")
                } catch EventGeneratorError.EventIdNotFound {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + "Specified event type is invalid. Check event method's arguement in json map file")
                } catch EventGeneratorError.InvalidParams(let string) {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + string)
                } catch {
                    throw MapObjectError.FailedToGenerate(eventListenerErrorMessage + "Unexpected error occured")
                }
                tile.events.append(event)
            }

            tiles[coordinate] = tile
        }
        return tiles
    }

    // MARK: -
}