//
//  TileSheet.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/08/03.
//  Copyright © 2015年 兎澤佑. All rights reserve d.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


/// TiledMapEditor で作成したマップを読み込み，クラスとして保持する
open class TileSheet {
    fileprivate let node: SKSpriteNode!
    fileprivate let frame: [SKShapeNode]!
    fileprivate let tileRowNum: Int
    fileprivate let tileColNum: Int
    fileprivate let drawingRangeWidth: CGFloat!
    fileprivate let drawingRangeHeight: CGFloat!
    fileprivate let drawingTileRows: Int!
    fileprivate let drawingTileCols: Int!

    ///  コンストラクタ
    ///
    ///  - parameter jsonFileName: タイルの情報を記述したjsonファイル名
    ///  - parameter frameWidth:   画面の横幅
    ///  - parameter frameHeight:  画面の縦幅
    ///
    ///  - returns: なし
    init?(
        parser: TiledMapJsonParser,
        frameWidth: CGFloat,
        frameHeight: CGFloat,
        tiles: Dictionary<TileCoordinate, Tile>,
        objects: Dictionary<TileCoordinate, [Object]>
    ) {
        var hasError:Bool = false
        var errMessageStack:[String] = []
        
        // 描画範囲のタイル数
        self.drawingTileRows = Int(frameWidth / Tile.TILE_SIZE)
        self.drawingTileCols = Int(frameHeight / Tile.TILE_SIZE)
        self.drawingRangeWidth  = (frameWidth  - CGFloat(drawingTileRows * Int(Tile.TILE_SIZE))) / 2
        self.drawingRangeHeight = (frameHeight - CGFloat(drawingTileCols * Int(Tile.TILE_SIZE))) / 2
        self.frame = TileSheet.createOuterFrameNodes(
            frameWidth,
            frameHeight: frameHeight,
            drawingRangeWidth: drawingRangeWidth,
            drawingRangeHeight: drawingRangeHeight
        )
        
        // マップのタイル数を取得
        var cols: Int
        var rows: Int
        do {
            (cols, rows) = try parser.getLayerSize()
            self.tileColNum = cols
            self.tileRowNum = rows
        } catch {
            self.tileColNum = -1
            self.tileRowNum = -1
            errMessageStack.append("タイル数取得失敗")
            hasError = true
        }
        
        // タイルシートの生成
        self.node = SKSpriteNode(
            color: UIColor.white,
            size: CGSize(width: CGFloat(tileRowNum) * Tile.TILE_SIZE,
            height: CGFloat(tileColNum) * Tile.TILE_SIZE)
        )
        self.node.position = CGPoint(x: drawingRangeWidth, y: drawingRangeHeight)
        // 左下が基準
        self.node.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        
        // タイルの追加
        for tile in tiles.values {
            tile.addTo(self.node)
        }
        
        // オブジェクトの追加
        for objectsOnTile in objects.values {
            for object in objectsOnTile {
                object.addTo(self.node)
            }
        }
        
        if hasError {
            for msg in errMessageStack { print(msg) }
            return nil
        }
    }

    ///  スクロールすべきか否かを検知し，すべきであればスクロール用のアクションを返す
    ///  キャラクターの移動ごとに呼び出される必要がある
    ///
    ///  - parameter position: キャラクターの現在位置
    ///
    ///  - returns: スクロールのためのアクション
    func scrollSheet(_ playerPosition: TileCoordinate) -> SKAction? {
        // 到達していたらスクロールするタイル
        // 原点沿いのタイル
        // WARNING: 補正値 +1
        let sheetOrigin = TileCoordinate.getTileCoordinateFromScreenCoordinate(
            self.node.position,
            screenCoordinate: CGPoint(x: self.drawingRangeWidth + 1, y: self.drawingRangeHeight + 1)
        )
        // 原点から見て画面端のタイル
        let max_x = sheetOrigin.x + self.drawingTileRows - 1
        let max_y = sheetOrigin.y + self.drawingTileCols - 1
        
        // スクロールするか？(プレイヤーの現在位置チェック)
        if ((    playerPosition.x >= max_x
              || playerPosition.y >= max_y
              || playerPosition.x <= sheetOrigin.x
              || playerPosition.y <= sheetOrigin.y
            ) == false) {
            return nil
        }

        var direction: DIRECTION

        if (playerPosition.x >= max_x) {
            direction = DIRECTION.right
        } else if (playerPosition.y >= max_y) {
            direction = DIRECTION.up
        } else if (playerPosition.x <= sheetOrigin.x) {
            direction = DIRECTION.left
        } else if (playerPosition.y <= sheetOrigin.y) {
            direction = DIRECTION.down
        } else {
            // WARNING: won't use
            direction = DIRECTION.up
        }

        var deltaX: CGFloat = 0
        var deltaY: CGFloat = 0
        switch (direction) {
        case .up:
            deltaX = 0
            deltaY = -(CGFloat(self.drawingTileCols - 1) * Tile.TILE_SIZE)
        case .down:
            deltaX = 0
            deltaY = CGFloat(self.drawingTileCols - 1) * Tile.TILE_SIZE
        case .left:
            deltaX = CGFloat(self.drawingTileRows - 1) * Tile.TILE_SIZE
            deltaY = 0
        case .right:
            deltaX = -(CGFloat(self.drawingTileRows - 1) * Tile.TILE_SIZE)
            deltaY = 0
        }
        return SKAction.moveBy(x: deltaX, y: deltaY, duration: 0.5)
    }

    ///  描画範囲外を黒く塗りつぶすための，画面の外枠を生成する
    ///
    ///  - parameter frameWidth:         画面横幅
    ///  - parameter frameHeight:        画面縦幅
    ///  - parameter drawingRangeWidth:  描画範囲横幅
    ///  - parameter drawingRangeHeight: 描画範囲縦幅
    ///
    ///  - returns: 生成した外枠のノード群
    fileprivate class func createOuterFrameNodes(_ frameWidth: CGFloat,
                                             frameHeight: CGFloat,
                                             drawingRangeWidth: CGFloat,
                                             drawingRangeHeight: CGFloat) -> [SKShapeNode]
    {
        var horizonalPoints = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: frameWidth, y: 0)]
        var verticalPoints  = [CGPoint(x: 0.0, y: 0.0), CGPoint(x: 0, y: frameHeight)]

        // 画面の縦横の長さと，フレーム枠の太さから，枠のテンプレートを作成
        let horizonalLine   = SKShapeNode(points: &horizonalPoints, count: horizonalPoints.count)
        horizonalLine.lineWidth = drawingRangeHeight * 2
        horizonalLine.strokeColor = UIColor.black
        horizonalLine.zPosition = zPositionTable.FLAME
        let verticalLine = SKShapeNode(points: &verticalPoints, count: verticalPoints.count)
        verticalLine.lineWidth = drawingRangeWidth * 2
        verticalLine.strokeColor = UIColor.black
        verticalLine.zPosition = zPositionTable.FLAME

        // 上下左右のフレーム枠の生成
        let underLine = horizonalLine.copy() as! SKShapeNode
        underLine.position = CGPoint(x: 0, y: 0)
        let upperLine = horizonalLine.copy() as! SKShapeNode
        upperLine.position = CGPoint(x: 0, y: frameHeight)
        let leftLine = verticalLine.copy() as! SKShapeNode
        leftLine.position = CGPoint(x: 0, y: 0)
        let rightLine = verticalLine.copy() as! SKShapeNode
        rightLine.position = CGPoint(x: frameWidth, y: 0)

        return [underLine, upperLine, leftLine, rightLine]
    }

    ///  指定された画面上の座標が，フレームの外枠上に乗っているかどうかの判定
    ///
    ///  - parameter position: 画面上の座標
    ///
    ///  - returns: 乗っていれば true, そうでなければ false
    func isOnFrame(_ position: CGPoint) -> Bool {
        if (position.x <= self.drawingRangeWidth
            || position.x >= self.drawingRangeWidth + CGFloat(self.drawingTileRows) * Tile.TILE_SIZE
            || position.y <= self.drawingRangeHeight
            || position.y >= self.drawingRangeHeight + CGFloat(self.drawingTileCols) * Tile.TILE_SIZE)
        {
            return true
        } else {
            return false
        }
    }

    ///  シーンにタイルシートを子ノードとして持たせる
    ///
    ///  - parameter scene: タイルシートを追加するシーン
    func addTo(_ scene: SKScene) {
        scene.addChild(self.node)
        for line in self.frame {
            scene.addChild(line)
        }
    }

    ///  タイルシートにオブジェクトを追加する
    ///
    ///  - parameter object: 追加するオブジェクト
    func addObjectToSheet(_ object: Object) {
        object.addTo(self.node)
    }

    ///  オブジェクト名から，対象オブジェクトの現在座標を取得する
    ///
    ///  - parameter name: 対象オブジェクト名
    ///
    ///  - returns: オブジェクトの現在位置
    func getObjectPositionByName(_ name: String) -> CGPoint? {
        return self.node.childNode(withName: name)?.position
    }

    ///  タイルシートにアクションを実行させる
    ///
    ///  - parameter actions:  実行させるアクション群
    ///  - parameter callback: コールバック
    func runAction(_ actions: Array<SKAction>, callback: @escaping () -> Void) {
        let sequence: SKAction = SKAction.sequence(actions)
        self.node.run(sequence, completion: { callback() })
    }

    func getSheetPosition() -> CGPoint {
        return self.node.position
    }
}
