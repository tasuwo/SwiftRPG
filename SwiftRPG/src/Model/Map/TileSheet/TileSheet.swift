//
//  TileSheet.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/08/03.
//  Copyright © 2015年 兎澤佑. All rights reserve d.
//

import Foundation
import UIKit
import SpriteKit
import SwiftyJSON

/// TiledMapEditor で作成したマップを読み込み，クラスとして保持する
public class TileSheet {
    /// タイルシートのノード
    private let sheetNode: SKSpriteNode!

    /// 描画範囲外を塗りつぶすノード群
    private let outerFrame: [SKShapeNode]!

    /// 敷き詰めるタイルの行数
    private let sheetTileRows: Int

    /// 敷き詰めるタイルの列数
    private let sheetTileCols: Int

    /// 描画範囲の横幅
    private let drawingRangeWidth: CGFloat!

    /// 描画範囲の縦幅
    private let drawingRangeHeight: CGFloat!

    /// 描画範囲内に描画されるタイル行数
    private let drawingTileRows: Int!

    /// 描画範囲内に描画されるタイルの列数
    private let drawingTileCols: Int!

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
        self.outerFrame = TileSheet.createOuterFrameNodes(
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
            self.sheetTileCols = cols
            self.sheetTileRows = rows
        } catch {
            self.sheetTileCols = -1
            self.sheetTileRows = -1
            errMessageStack.append("タイル数取得失敗")
            hasError = true
        }
        
        // タイルシートの生成
        self.sheetNode = SKSpriteNode(
            color: UIColor.whiteColor(),
            size: CGSizeMake(CGFloat(sheetTileRows) * Tile.TILE_SIZE,
            CGFloat(sheetTileCols) * Tile.TILE_SIZE)
        )
        self.sheetNode.position = CGPointMake(drawingRangeWidth, drawingRangeHeight)
        // 左下が基準
        self.sheetNode.anchorPoint = CGPointMake(0.0, 0.0)
        
        // タイルの追加
        for tile in tiles.values {
            tile.addTo(self.sheetNode)
        }
        
        // オブジェクトの追加
        for objectsOnTile in objects.values {
            for object in objectsOnTile {
                object.addTo(self.sheetNode)
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
    func scrollSheet(playerPosition: TileCoordinate) -> SKAction? {
        // 到達していたらスクロールするタイル
        // 原点沿いのタイル
        // WARNING: 補正値 +1
        let sheetOrigin = TileCoordinate.getTileCoordinateFromScreenCoordinate(
            self.sheetNode.position,
            screenCoordinate: CGPointMake(self.drawingRangeWidth + 1, self.drawingRangeHeight + 1)
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
            direction = DIRECTION.RIGHT
        } else if (playerPosition.y >= max_y) {
            direction = DIRECTION.UP
        } else if (playerPosition.x <= sheetOrigin.x) {
            direction = DIRECTION.LEFT
        } else if (playerPosition.y <= sheetOrigin.y) {
            direction = DIRECTION.DOWN
        } else {
            // WARNING: won't use
            direction = DIRECTION.UP
        }

        var deltaX: CGFloat = 0
        var deltaY: CGFloat = 0
        switch (direction) {
        case .UP:
            deltaX = 0
            deltaY = -(CGFloat(self.drawingTileCols - 1) * Tile.TILE_SIZE)
        case .DOWN:
            deltaX = 0
            deltaY = CGFloat(self.drawingTileCols - 1) * Tile.TILE_SIZE
        case .LEFT:
            deltaX = CGFloat(self.drawingTileRows - 1) * Tile.TILE_SIZE
            deltaY = 0
        case .RIGHT:
            deltaX = -(CGFloat(self.drawingTileRows - 1) * Tile.TILE_SIZE)
            deltaY = 0
        }
        return SKAction.moveByX(deltaX, y: deltaY, duration: 0.5)
    }

    ///  描画範囲外を黒く塗りつぶすための，画面の外枠を生成する
    ///
    ///  - parameter frameWidth:         画面横幅
    ///  - parameter frameHeight:        画面縦幅
    ///  - parameter drawingRangeWidth:  描画範囲横幅
    ///  - parameter drawingRangeHeight: 描画範囲縦幅
    ///
    ///  - returns: 生成した外枠のノード群
    private class func createOuterFrameNodes(frameWidth: CGFloat,
                                             frameHeight: CGFloat,
                                             drawingRangeWidth: CGFloat,
                                             drawingRangeHeight: CGFloat) -> [SKShapeNode]
    {
        var horizonalPoints = [CGPointMake(0.0, 0.0), CGPointMake(frameWidth, 0)]
        var verticalPoints  = [CGPointMake(0.0, 0.0), CGPointMake(0, frameHeight)]

        // 画面の縦横の長さと，フレーム枠の太さから，枠のテンプレートを作成
        let horizonalLine   = SKShapeNode(points: &horizonalPoints, count: horizonalPoints.count)
        horizonalLine.lineWidth = drawingRangeHeight * 2
        horizonalLine.strokeColor = UIColor.blackColor()
        horizonalLine.zPosition = zPositionTable.FLAME
        let verticalLine = SKShapeNode(points: &verticalPoints, count: verticalPoints.count)
        verticalLine.lineWidth = drawingRangeWidth * 2
        verticalLine.strokeColor = UIColor.blackColor()
        verticalLine.zPosition = zPositionTable.FLAME

        // 上下左右のフレーム枠の生成
        let underLine = horizonalLine.copy() as! SKShapeNode
        underLine.position = CGPointMake(0, 0)
        let upperLine = horizonalLine.copy() as! SKShapeNode
        upperLine.position = CGPointMake(0, frameHeight)
        let leftLine = verticalLine.copy() as! SKShapeNode
        leftLine.position = CGPointMake(0, 0)
        let rightLine = verticalLine.copy() as! SKShapeNode
        rightLine.position = CGPointMake(frameWidth, 0)

        return [underLine, upperLine, leftLine, rightLine]
    }

    ///  指定された画面上の座標が，フレームの外枠上に乗っているかどうかの判定
    ///
    ///  - parameter position: 画面上の座標
    ///
    ///  - returns: 乗っていれば true, そうでなければ false
    func isOnFrame(position: CGPoint) -> Bool {
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
    func addTo(scene: SKScene) {
        scene.addChild(self.sheetNode)
        for line in self.outerFrame {
            scene.addChild(line)
        }
    }

    ///  タイルシートにオブジェクトを追加する
    ///
    ///  - parameter object: 追加するオブジェクト
    func addObjectToSheet(object: Object) {
        object.addTo(self.sheetNode)
    }

    ///  オブジェクト名から，対象オブジェクトの現在座標を取得する
    ///
    ///  - parameter name: 対象オブジェクト名
    ///
    ///  - returns: オブジェクトの現在位置
    func getObjectPositionByName(name: String) -> CGPoint? {
        return self.sheetNode.childNodeWithName(name)?.position
    }

    ///  タイルシートにアクションを実行させる
    ///
    ///  - parameter actions:  実行させるアクション群
    ///  - parameter callback: コールバック
    func runAction(actions: Array<SKAction>, callback: () -> Void) {
        let sequence: SKAction = SKAction.sequence(actions)
        self.sheetNode.runAction(sequence, completion: { callback() })
    }

    func getSheetPosition() -> CGPoint {
        return self.sheetNode.position
    }
}
