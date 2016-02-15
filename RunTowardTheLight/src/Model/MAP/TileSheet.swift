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

enum DIRECTION {
    case UP, DOWN, LEFT, RIGHT
}

// TODO : ちゃんとエラーハンドリングする
enum E : ErrorType {
    case error
}

// TODO: 位置情報の管理は別クラスに分ける
/// ゲームの1エリアに相当する，タイルを敷き詰めたシート
class TileSheet {
    /// ノード
    private let sheet_: SKSpriteNode!
    
    /// 敷き詰めるタイルの行数
    private let sheetTileRows_: Int
    
    /// 敷き詰めるタイルの列数
    private let sheetTileCols_: Int
    
    /// 描画範囲の横幅
    private let drawingRangeWidth_: CGFloat!
    
    /// 描画範囲の縦幅
    private let drawingRangeHeight_: CGFloat!
    
    /// 描画範囲内に描画されるタイル行数
    private let drawingTileRows_: Int!
    
    /// 描画範囲内に描画されるタイルの列数
    private let drawingTileCols_: Int!
    
    /// 画面上におけるタイルシートの描画範囲．描画範囲外は黒く塗りつぶされる
    private var outerFrame_: [SKShapeNode] = []
    
    /// 敷き詰めたタイルを保持しておくディクショナリ
    private var tileDic_: Dictionary<TileCoordinate, Tile>
    
    /// オブジェクトを保持しておくディクショナリ
    private var objectDic_: Dictionary<String, Object>
    
    /// 各タイルの情報を保持しておくディクショナリ
    private let tileInfoDic_: Dictionary<TileCoordinate, TileInfo>
    
    /// 各タイルセットの情報を保持しておくディクショナリ
    private let tileSetsInfoDic_: Dictionary<TileSetID, TileSetInfo>
    
    
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
        frameHeight: CGFloat
    ) {
        var hasError:Bool = false
        var errMessageStack:[String] = []
        
        // シート内のタイル数
        var cols: Int
        var rows: Int
        do {
            (cols, rows) = try parser.getLayerSize()
            self.sheetTileCols_ = cols
            self.sheetTileRows_ = rows
        } catch {
            self.sheetTileCols_ = -1
            self.sheetTileRows_ = -1
            errMessageStack.append("タイル数取得失敗")
            hasError = true
        }
        
        // パーサを利用して各情報を読み込み
        do {
            self.tileInfoDic_ = try parser.getTileInfoArray(
                self.sheetTileCols_,
                layerTileRows: self.sheetTileRows_
            )
        } catch {
            self.tileInfoDic_ = [:]
            errMessageStack.append("tile info 取得失敗")
            hasError = true
        }
        do {
           self.tileSetsInfoDic_ = try parser.getTileSetsInfo()
        } catch {
            self.tileSetsInfoDic_ = [:]
            errMessageStack.append("tile set info 取得失敗")
            hasError = true
        }
        
        // 描画範囲のタイル数
        self.drawingTileRows_ = Int(frameWidth / Tile.TILE_SIZE)
        self.drawingTileCols_ = Int(frameHeight / Tile.TILE_SIZE)
        self.drawingRangeWidth_  = (frameWidth  - CGFloat(drawingTileRows_ * Int(Tile.TILE_SIZE))) / 2
        self.drawingRangeHeight_ = (frameHeight - CGFloat(drawingTileCols_ * Int(Tile.TILE_SIZE))) / 2
        self.outerFrame_ = TileSheet.createOuterFrameNodes(
            frameWidth,
            frameHeight: frameHeight,
            drawingRangeWidth: drawingRangeWidth_,
            drawingRangeHeight: drawingRangeHeight_
        )
        
        // タイルシートの生成
        self.sheet_ = SKSpriteNode(
            color: UIColor.whiteColor(),
            size: CGSizeMake(CGFloat(sheetTileRows_) * Tile.TILE_SIZE,
            CGFloat(sheetTileCols_) * Tile.TILE_SIZE)
        )
        self.sheet_.position = CGPointMake(drawingRangeWidth_, drawingRangeHeight_)
        self.sheet_.anchorPoint = CGPointMake(0.0, 0.0)
        
        // 各タイルの生成・追加
        do {
            let properties = try parser.getTileProperties()
            self.tileDic_ = try TileSheet.createTiles(
                self.sheetTileRows_,
                tileCols: self.sheetTileCols_,
                parser: parser,
                tileInformations: self.tileInfoDic_,
                tileSetsInformations: self.tileSetsInfoDic_,
                tileProperties: properties)
        } catch {
            self.tileDic_ = [:]
            errMessageStack.append("タイル生成失敗")
            hasError = true
        }
        for tile in self.tileDic_.values {
            tile.addTo(self.sheet_)
        }
        
        // 各オブジェクトの生成・追加
        do {
            self.objectDic_ = try TileSheet.createObjects(
                parser,
                tileInformations: self.tileInfoDic_,
                tileSetsInformations: self.tileSetsInfoDic_,
                tileDic: self.tileDic_
            )
        } catch {
            self.objectDic_ = [:]
            errMessageStack.append("オブジェクト生成失敗")
            hasError = true
        }
        for object in self.objectDic_.values {
            object.addTo(self.sheet_)
        }
        
        if hasError {
            for msg in errMessageStack {
                print(msg)
            }
            return nil
        }
    }
    
    
    ///  描画範囲外を黒く塗りつぶすための，画面の外枠を生成する
    ///
    ///  - parameter frameWidth:         画面横幅
    ///  - parameter frameHeight:        画面縦幅
    ///  - parameter drawingRangeWidth:  描画範囲横幅
    ///  - parameter drawingRangeHeight: 描画範囲縦幅
    ///
    ///  - returns: 生成した外枠のノード群
    private class func createOuterFrameNodes(
        frameWidth: CGFloat,
        frameHeight: CGFloat,
        drawingRangeWidth: CGFloat,
        drawingRangeHeight: CGFloat
        ) -> [SKShapeNode] {
            var horizonalPoints = [CGPointMake(0.0, 0.0), CGPointMake(frameWidth, 0)]
            var verticalPoints  = [CGPointMake(0.0, 0.0), CGPointMake(0, frameHeight)]
            
            // 画面の縦横の長さと，フレーム枠の太さから，枠のテンプレートを作成
            let horizonalLine   = SKShapeNode(points: &horizonalPoints, count: horizonalPoints.count)
            horizonalLine.lineWidth = drawingRangeHeight * 2
            horizonalLine.strokeColor = UIColor.blackColor()
            horizonalLine.zPosition = 10
            let verticalLine = SKShapeNode(points: &verticalPoints, count: verticalPoints.count)
            verticalLine.lineWidth = drawingRangeWidth * 2
            verticalLine.strokeColor = UIColor.blackColor()
            verticalLine.zPosition = 10
            
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
    
    
    ///  各タイルを生成し，配列及びタイルシートへ追加する
    ///
    ///  - parameter tileRows:  シートに敷き詰めるタイルの行数
    ///  - parameter tileCols:  シートに敷き詰めるタイルの列数
    ///  - parameter parser:    jsonファイルを読み込んだパーサ
    ///  - parameter tileArray: 生成したタイルを保持しておく配列
    ///  - parameter sheet:     タイルのノードを追加するタイルシート
    ///
    ///  - throws: 失敗時
    private class func createTiles(
        tileRows: Int,
        tileCols: Int,
        parser:   TiledMapJsonParser,
        tileInformations: Dictionary<TileCoordinate, TileInfo>,
        tileSetsInformations: Dictionary<TileSetID, TileSetInfo>,
        tileProperties: Dictionary<TileID, TileProperty>
        ) throws -> Dictionary<TileCoordinate, Tile>
    {
        do {
            var tileDic: Dictionary<TileCoordinate, Tile> = [:]
            
            for (var x = 1; x <= tileRows; x++) {
                for (var y = 1; y <= tileCols; y++) {
                    let tileInfo: TileInfo
                    if let info = tileInformations[TileCoordinate(x: x, y: y)] {
                        tileInfo = info
                    } else {
                        // タイルのinfoが存在しない
                        throw E.error
                    }
                    
                    let tileID   = tileInfo.tileID
                    let property: TileProperty
                    if let prop = tileProperties[tileID] {
                        property = prop
                    } else {
                        // タイルのプロパティが存在しない
                        throw E.error
                    }
                    
                    // タイルを作成する
                    let tile = Tile(
                        coordinate: TileCoordinate(x: x, y: y),
                        event: nil
                    )
                    
                    // 当たり判定を付加する
                    if tileInfo.hasCollision == true {
                        tile.setCollision()
                    }
                    
                    // 画像を付加する
                    if let tileSetIDstr = property["tileSetID"],
                       let tileSetID = Int(tileSetIDstr) {
                        let tileImage = try parser.cropTileImage(
                            tileSetID,
                            tileID: tileID,
                            tileSetInformations: tileSetsInformations)
                        tile.setImageWithUIImage(tileImage)
                    }
                    
                    // イベントを付加する
                    if let action = property["event"] {
                        let events = EventDispatcher<AnyObject?>()
                        events.add(GameSceneEvent.events[action]!(nil))
                        tile.setEvent(events)
                    }
                    
                    tileDic[TileCoordinate(x: x, y: y)] = tile
                }
            }
            
            return tileDic
        } catch {
            // TODO: Error handling
            throw error
        }
    }
    
    
    ///  オブジェクトを生成する
    ///  WARNING : タイルの配列を直接いじっている．切り分けるべきかもしれない
    ///
    ///  - parameter tileRows:         シートに敷き詰めるタイルの行数
    ///  - parameter tileCols:         シートに敷き詰めるタイルの列数
    ///  - parameter parser:           jsonファイルのパーサ
    ///  - parameter tileInformations: タイル情報を格納したディクショナリ
    ///  - parameter tileArray:        タイルを格納した配列
    ///
    ///  - throws: 失敗時
    ///
    ///  - returns: オブジェクトの配列
    private class func createObjects(
        parser:   TiledMapJsonParser,
        tileInformations: Dictionary<TileCoordinate, TileInfo>,
        tileSetsInformations: Dictionary<TileSetID, TileSetInfo>,
        tileDic: Dictionary<TileCoordinate, Tile>
    ) throws -> Dictionary<String, Object> {
        var objectDic: Dictionary<String, Object> = [:]
        let tileProperties = try parser.getTileProperties()
        
        // オブジェクトの配置
        for (coordinate, _) in tileDic {
            let tileInfo: TileInfo
            if let info = tileInformations[coordinate] {
                tileInfo = info
            } else {
                // tile info が存在しない
                throw E.error
            }
            
            // オブジェクト判定
            let objectID = Int(tileInfo.objectID)
            if objectID != 0 {
                if tileProperties[objectID] == nil {
                    throw E.error
                }
                let property = tileProperties[objectID]!
                
                let tileSetID = Int(property["tileSetID"]!)
                do {
                    let obj_image = try parser.cropTileImage(
                        tileSetID!,
                        tileID: objectID,
                        tileSetInformations: tileSetsInformations)
                    let name = property["tileSetName"]! + "_" + NSUUID().UUIDString
                    objectDic[name] = Object(
                        name: name, /* 一意の名前をつける */
                        imageData: obj_image,
                        position: TileSheet.getTileCenterPosition(coordinate)
                    )
                } catch {
                    throw E.error
                }
                
                // 当たり判定
                // TODO: 本来はタイルではなくオブジェクトに当たり判定をつける
                if let hasCollision = property["collision"] {
                    if hasCollision == "1" {
                        tileDic[coordinate]?.setCollision()
                    }
                }
                
                // obj のイベントは全てこれで良いか？多分良くない...
                // 落ちてるもののイベントだってあるだろう．現状は，当たり判定がある obj 限定
                if let obj_action = property["event"] {
                    let events = EventDispatcher<AnyObject?>()
                    events.add(GameSceneEvent.events[obj_action]!(nil))
                    // 周囲四方向のタイルにイベントを設置
                    // 各方向に違うイベントが設置できない
                    let x = coordinate.getX()
                    let y = coordinate.getY()
                    tileDic[TileCoordinate(x: x - 1, y: y)]?.setEvent(events)
                    tileDic[TileCoordinate(x: x + 1, y: y)]?.setEvent(events)
                    tileDic[TileCoordinate(x: x, y: y - 1)]?.setEvent(events)
                    tileDic[TileCoordinate(x: x, y: y + 1)]?.setEvent(events)
                }
            }
        }
        
        return objectDic
    }
    
    
    func runAction(actions: Array<SKAction>, callback: () -> Void) {
        let sequence: SKAction = SKAction.sequence(actions)
        sheet_.runAction(sequence, completion: {
            callback()
        })
    }
    
    
    ///  シーンにタイルシートを子ノードとして持たせる
    ///
    ///  - parameter scene: タイルシートを追加するシーン
    func addTilesheetTo(scene: SKScene) {
        scene.addChild(sheet_)
        for line in outerFrame_ {
            scene.addChild(line)
        }
    }
    
    
    ///  オブジェクトの向きを取得する
    ///
    ///  - parameter objectName: オブジェクト名
    ///
    ///  - returns: オブジェクトの向き
    func getPlayerDirection(objectName: String) -> DIRECTION {
        let object: Object = objectDic_[objectName]!
        return object.getDirection()
    }
    
    
    ///  オブジェクトの速さを取得する
    ///
    ///  - parameter objectName: オブジェクト名
    ///
    ///  - returns: オブジェクトの速さ
    func getPlayerSpeed(objectName: String) -> CGFloat {
        let object: Object = objectDic_[objectName]!
        return object.getMovingSpeed()
    }
    
    
    ///  スクロールすべきか否かを検知し，すべきであればスクロール用のアクションを返す
    ///  キャラクターの移動ごとに呼び出される必要がある
    ///
    ///  - parameter position: キャラクターの現在位置
    ///
    ///  - returns: スクロールのためのアクション
    func detectScroll(position: TileCoordinate) -> SKAction? {
        // 到達していたらスクロールするタイル
        // 原点沿いのタイル
        // WARNING: 補正値 +1
        let sheetOrigin = self.getTileCoordinateNear(
            CGPointMake(drawingRangeWidth_ + 1, drawingRangeHeight_ + 1)
        )
        // 原点から見て画面端のタイル
        let max_x = sheetOrigin.getX() + drawingTileRows_ - 1
        let max_y = sheetOrigin.getY() + drawingTileCols_ - 1
        
        // スクロールするか？(プレイヤーの現在位置チェック)
        if (position.getX() >= max_x
            || position.getY() >= max_y
            || position.getX() <= sheetOrigin.getX()
            || position.getY() <= sheetOrigin.getY()) {
                var direction: DIRECTION
                
                if (position.getX() >= max_x) {
                    direction = DIRECTION.RIGHT
                } else if (position.getY() >= max_y) {
                    direction = DIRECTION.UP
                } else if (position.getX() <= sheetOrigin.getX()) {
                    direction = DIRECTION.LEFT
                } else if (position.getY() <= sheetOrigin.getY()) {
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
                    deltaY = -(CGFloat(drawingTileCols_ - 1) * Tile.TILE_SIZE)
                case .DOWN:
                    deltaX = 0
                    deltaY = CGFloat(drawingTileCols_ - 1) * Tile.TILE_SIZE
                case .LEFT:
                    deltaX = CGFloat(drawingTileRows_ - 1) * Tile.TILE_SIZE
                    deltaY = 0
                case .RIGHT:
                    deltaX = -(CGFloat(drawingTileRows_ - 1) * Tile.TILE_SIZE)
                    deltaY = 0
                }
                return SKAction.moveByX(
                    deltaX,
                    y: deltaY,
                    duration: 0.5
                )
        }
        return nil
    }
    
    
    ///  タイルシート上にオブジェクトを追加，配置する
    ///
    ///  - parameter name:       オブジェクト名
    ///  - parameter image:      オブジェクトのイメージ
    ///  - parameter coordinate: 配置する座標
    func placementObjectOnTileWithUIImage(name: String, image: UIImage, coordinate: TileCoordinate) {
        let object = Object(name: name,
            imageData: image,
            position: TileSheet.getTileCenterPosition(coordinate))
        object.addTo(sheet_)
        objectDic_ = [name: object]
    }
    
    
    ///  タイルシート上にオブジェクトを追加，配置する
    ///
    ///  - parameter name:       オブジェクト名
    ///  - parameter image_name: オブジェクトの画像ファイル名
    ///  - parameter coordinate: 配置する座標
    func placementObjectOnTileWithName(name: String, image_name: String, coordinate: TileCoordinate) {
        let object = Object(name: name,
            imageName: image_name,
            position: TileSheet.getTileCenterPosition(coordinate))
        object.addTo(sheet_)
        objectDic_ = [name: object]
    }
    
    
    ///  指定された画面上の座標が，フレームの外枠上に乗っているかどうかの判定
    ///
    ///  - parameter position: 画面上の座標
    ///
    ///  - returns: 乗っていれば true, そうでなければ false
    func isOnFrame(position: CGPoint) -> Bool {
        if (position.x <= drawingRangeWidth_
            || position.x >= drawingRangeWidth_ + CGFloat(drawingTileRows_) * Tile.TILE_SIZE
            || position.y <= drawingRangeHeight_
            || position.y >= drawingRangeHeight_ + CGFloat(drawingTileCols_) * Tile.TILE_SIZE
            ) {
                return true
        } else {
            return false
        }
    }
    
    
    ///  オブジェクトのタイルシート上の座標を取得する．
    ///
    ///  - parameter name: オブジェクト名
    ///
    ///  - returns: オブジェクトのシート上の座標
    func getObjectTileCoordinateBy(name: String) -> TileCoordinate? {
        return getTileCoordinateNearOnSheet((objectDic_[name]?.getPosition())!)
    }
    
    
    ///  オブジェクトの画面上の位置を取得する
    ///
    ///  - parameter name: オブジェクト名
    ///
    ///  - returns: 画面上の座標
    func getObjectPosition(name: String) -> CGPoint {
        return (objectDic_[name]?.getPosition())!
    }
    
    
    ///  タイルの通行可否を判断する
    ///
    ///  - parameter coordinate: 対象タイルの座標
    ///
    ///  - returns: 通行可能ならば true, そうでなければ false
    func canPassTile(coordinate: TileCoordinate) -> Bool? {
        let hasCollision = tileInfoDic_[coordinate]!.hasCollision
        if hasCollision {
            return false
        } else {
            return self.tileDic_[coordinate]?.canPass()
        }
    }
    
    
    ///  オブジェクトが特定座標まで移動するためのアクションを取得する
    ///
    ///  - parameter objectName: アクションを実行させるオブジェクト
    ///  - parameter to:         移動先のタイルシート座標
    ///
    ///  - returns: アニメーションの配列
    func getActionTo(objectName: String, to: TileCoordinate) -> Array<SKAction> {
        let object: Object = objectDic_[objectName]!
        let destination = TileSheet.getTileCenterPosition(to)
        return object.getActionTo(destination)
    }
    
    
    ///  あるタイル上のイベントを取得する
    ///
    ///  - parameter coordinate: 対象タイルのタイルシート座標
    ///
    ///  - returns: イベント
    func isEventOn(coordinate: TileCoordinate) -> EventDispatcher<AnyObject?>? {
        return self.tileDic_[coordinate]?.getEvent()
    }
    
    
    func moveObject(objectName: String, actions: Array<SKAction>, callback: () -> Void) {
        let object: Object = objectDic_[objectName]!
        object.runAction(actions, callback: callback)
    }
    
    
    // タッチされた位置に最も近いタイルの中心座標を返す
    func getTilePositionNear(pointOnScreen: CGPoint) -> CGPoint {
        return TileSheet.getTileCenterPosition(getTileCoordinateNear(pointOnScreen))
    }
    
    
    // 画面上の座標に最も近い，タイル位置を返す
    func getTileCoordinateNear(pointOnScreen: CGPoint) -> TileCoordinate {
        return TileCoordinate(
            x: Int(floor(
                (pointOnScreen.x - sheet_.position.x) / CGFloat(Tile.TILE_SIZE) + 1)),
            y: Int(floor(
                (pointOnScreen.y - sheet_.position.y) / CGFloat(Tile.TILE_SIZE) + 1)))
    }
    
    
    private func getTileCoordinateNearOnSheet(pointOnScreen: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor(pointOnScreen.x / CGFloat(Tile.TILE_SIZE) + 1)),
            y: Int(floor(pointOnScreen.y / CGFloat(Tile.TILE_SIZE) + 1)))
    }
    
    
    // 指定したタイルの中心の座標を返す
    class func getTileCenterPosition(coordinate: TileCoordinate) -> CGPoint {
        return CGPointMake(
            CGFloat(coordinate.getX()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2,
            CGFloat(coordinate.getY()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2
        )
    }
}
