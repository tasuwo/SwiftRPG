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
    private let tile_: SKSpriteNode
    
    /// サイズ
    static var TILE_SIZE: CGFloat = 32.0
    
    /// 座標
    private var coordinate_: TileCoordinate
    
    /// イベント
    internal var event: EventDispatcher<Any>?
    
    /// プロパティ
    private var property_: TileProperty
    
    /// 当たり判定
    internal var hasCollision: Bool

    ///  コンストラクタ
    ///
    ///  - parameter coordinate: タイルの座標
    ///  - parameter event:      タイルに配置するイベント
    ///
    ///  - returns: なし
    init(id: TileID, coordinate: TileCoordinate, property: TileProperty) {
        let x = coordinate.getX()
        let y = coordinate.getY()
        self.tileID = id
        self.tile_ = SKSpriteNode()
        self.tile_.size = CGSizeMake(CGFloat(Tile.TILE_SIZE),
                                     CGFloat(Tile.TILE_SIZE))
        self.tile_.position = CGPointMake(CGFloat(x - 1) * Tile.TILE_SIZE,
                                          CGFloat(y - 1) * Tile.TILE_SIZE)
        self.tile_.anchorPoint = CGPointMake(0.0, 0.0)
        self.tile_.zPosition = zPositionTable.TILE
        self.coordinate_ = TileCoordinate(x: x, y: y)
        self.hasCollision = false
        self.property_ = property
    }
    

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter imageName: 付加するテクスチャ画像名
    func setImageWithName(imageName: String) {
        tile_.texture = SKTexture(imageNamed: imageName)
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter image: 付加するテクスチャ画像
    func setImageWithUIImage(image: UIImage) {
        tile_.texture = SKTexture(image: image)
    }

    ///  タイルのノードに子ノードを追加する
    ///
    ///  - parameter node: 追加する子ノード
    func addTo(node: SKSpriteNode) {
        node.addChild(tile_)
    }
    
    
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
        ) throws -> Dictionary<TileCoordinate, Tile>
    {
        do {
            var tiles: Dictionary<TileCoordinate, Tile> = [:]
            for (coordinate, _) in tilePlacement {
                let hasCollision: Int
                let tileID: Int
                let tileProperty: TileProperty
                if
                    let col = collisionPlacement[coordinate],
                    let id = tilePlacement[coordinate],
                    let prop = properties[id]
                {
                    hasCollision = col
                    tileID = id
                    tileProperty = prop
                } else {
                    // TODO : 真面目にエラーハンドリングする
                    print("タイル情報取得失敗")
                    throw E.error
                }
                
                // タイルを作成する
                let tile = Tile(
                    id: tileID,
                    coordinate: coordinate,
                    property: tileProperty
                )
                
                // 当たり判定を付加する
                if hasCollision != 0 { tile.setCollision() }
                
                // 画像を付加する
                if let tileSetIDstr = tile.getProperty("tileSetID"),
                   let tileSetID = Int(tileSetIDstr),
                   let tileSet = tileSets[tileSetID]
                {
                    let tileImage = try tileSet.cropTileImage(tileID)
                    tile.setImageWithUIImage(tileImage)
                }
                
                // イベントを付加する
                if let action = tile.getProperty("event") {
                    let events = EventDispatcher<Any>()
                    events.add(GameSceneEvent.events[action]!(nil))
                    tile.event = events
                }
                
                tiles[coordinate] = tile
            }
            return tiles
        } catch {
            // TODO: Error handling
            print("cropImage失敗")
            throw error
        }
    }
    
    func setEvent(event: EventDispatcher<Any>) {
        self.event = event
    }
    
    func getEvent() -> EventDispatcher<Any>? {
        return self.event
    }
    
    func setCollision() {
        self.hasCollision = true
    }
    
    func canPass() -> Bool {
        return hasCollision
    }
    
    func getCoordinate() -> TileCoordinate {
        return self.coordinate_
    }
    
    func getProperty(name: String) -> String? {
        return self.property_[name]
    }
    
    func getProperties() -> TileProperty {
        return self.property_
    }
}