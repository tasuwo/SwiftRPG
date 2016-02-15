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

/// マップ上に敷かれる各タイルに対応した SKSpriteNode のラッパークラス
class Tile {
    /// ノード
    private let tile_: SKSpriteNode
    
    /// サイズ
    static var TILE_SIZE: CGFloat = 32.0
    
    /// 座標
    private var coordinate_: TileCoordinate
    
    /// 当たり判定
    private var hasCollision_: Bool
    
    /// イベント
    private var event_: EventDispatcher<AnyObject?>?

    ///  コンストラクタ
    ///
    ///  - parameter coordinate: タイルの座標
    ///  - parameter event:      タイルに配置するイベント
    ///
    ///  - returns: なし
    init(coordinate: TileCoordinate, event: EventDispatcher<AnyObject?>?) {
        let x = coordinate.getX()
        let y = coordinate.getY()

        tile_ = SKSpriteNode()
        tile_.size = CGSizeMake(CGFloat(Tile.TILE_SIZE),
                                CGFloat(Tile.TILE_SIZE))
        tile_.position = CGPointMake(CGFloat(x - 1) * Tile.TILE_SIZE,
                                     CGFloat(y - 1) * Tile.TILE_SIZE)
        tile_.anchorPoint = CGPointMake(0.0, 0.0)
        coordinate_ = TileCoordinate(x: x, y: y)
        hasCollision_ = false

        event_ = event
    }
    
    func getCoordinate() -> TileCoordinate {
        return self.coordinate_
    }
    
    func getEvent() -> EventDispatcher<AnyObject?>? {
        return event_
    }
    
    func canPass() -> Bool {
        return !hasCollision_
    }

    func setEvent(event: EventDispatcher<AnyObject?>) {
        event_ = event
    }
    
    ///  タイルに当たり判定を付加する
    func setCollision() {
        hasCollision_ = true
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter imageName: 付加するテクスチャ画像名
    func setImageWithName(imageName: String) {
        tile_.texture = SKTexture(imageNamed: imageName)
    }

    ///  タイルにテクスチャ画像を付加する
    ///
    ///  - parameter image: 孵化するテクスチャ画像
    func setImageWithUIImage(image: UIImage) {
        tile_.texture = SKTexture(image: image)
    }

    ///  タイルのノードに子ノードを追加する
    ///
    ///  - parameter node: 追加する子ノード
    func addTo(node: SKSpriteNode) {
        node.addChild(tile_)
    }
}