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
    fileprivate var objects: Dictionary<MapObjectId, Object> = [:]
    fileprivate var tiles: Dictionary<MapObjectId, Tile> = [:]
    fileprivate var events: Dictionary<MapObjectId, EventObject> = [:]
    fileprivate var objectsPlacement: Dictionary<TileCoordinate, [MapObjectId]> = [:]
    fileprivate var tilesPlacement: Dictionary<TileCoordinate, MapObjectId> = [:]
    fileprivate var eventsPlacement: Dictionary<TileCoordinate, [MapObjectId]> = [:]

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
        objects: Dictionary<TileCoordinate, [Object]>,
        events: Dictionary<TileCoordinate, [EventObject]>
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
        
        // Add Tiles
        for (coordinate, tile) in tiles {
            tile.addTo(self.node)
            self.tiles[tile.id] = tile
            self.tilesPlacement[coordinate] = tile.id
        }

        // Add Objects
        for (coordinate, objectsOnTile) in objects {
            self.objectsPlacement[coordinate] = []
            for object in objectsOnTile {
                object.addTo(self.node)
                self.objects[object.id] = object
                self.objectsPlacement[coordinate]?.append(object.id)
            }
        }

        // Add Events
        for (coordinate, eventsOnTile) in events {
            self.eventsPlacement[coordinate] = []
            for event in eventsOnTile {
                self.events[event.id] = event
                self.eventsPlacement[coordinate]?.append(event.id)
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

    func addTo(_ scene: SKScene) {
        scene.addChild(self.node)
        for line in self.frame {
            scene.addChild(line)
        }
    }

    func addObjectToSheet(_ object: Object) {
        object.addTo(self.node)
    }

    func getObjectPositionByName(_ name: String) -> CGPoint? {
        return self.node.childNode(withName: name)?.position
    }

    func runAction(_ actions: Array<SKAction>, callback: @escaping () -> Void) {
        let sequence: SKAction = SKAction.sequence(actions)
        self.node.run(sequence, completion: { callback() })
    }

    func getSheetPosition() -> CGPoint {
        return self.node.position
    }

    // setter

    func setObject(object: Object, coordinate: TileCoordinate) {
        self.objects[object.id] = object
        if (self.objectsPlacement[coordinate]?.isEmpty)! {
            self.objectsPlacement[coordinate] = [object.id]
        } else {
            self.objectsPlacement[coordinate]?.append(object.id)
        }
        self.addObjectToSheet(object)
    }

    func removeEventsOfObject(_ objectId: MapObjectId) {
        let object = self.objects[objectId]
        for eventObjectId in (object?.children)! {
            self.removeEventObjects(eventObjectId)
        }
    }

    func removeEventObjects(_ eventObjectId: MapObjectId) {
        var target: (cor: TileCoordinate, i: Int)? = nil
        for eventPlacement in self.eventsPlacement {
            let ids = eventPlacement.value
            for (index, id) in ids.enumerated() {
                if id == eventObjectId {
                    target = (cor: eventPlacement.key, i: index)
                    break
                }
            }
        }

        if let t = target {
            self.eventsPlacement[t.cor]?.remove(at: t.i)
        }
    }

    // TODO: More efficiency
    //       Need reference to tileCoordinate from mapObject
    func removeObject(_ mapObjectId: MapObjectId) {
        var target: (cor: TileCoordinate, i: Int)? = nil
        for objectPlacement in self.objectsPlacement {
            let ids = objectPlacement.value
            for (index, id) in ids.enumerated() {
                if id == mapObjectId {
                    target = (cor: objectPlacement.key, i: index)
                    break
                }
            }
        }

        if let t = target {
            self.objectsPlacement[t.cor]?.remove(at: t.i)
        }
    }

    func setEventsOf(_ objectId: MapObjectId, coordinate: TileCoordinate) {
        let eventIds = self.objects[objectId]?.children
        if eventIds == nil { return }
        for eventId in eventIds! {
            if let relativeCoordinate = self.events[eventId]?.relativeCoordinateFromParent {
                let cor = coordinate + relativeCoordinate
                if (self.eventsPlacement[cor] != nil) {
                    self.eventsPlacement[cor]!.append(eventId)
                } else {
                    self.eventsPlacement[cor] = [eventId]
                }
            }
        }
    }

    // getter for MapObjects

    func getAllObjects() -> [Object] {
        var objects: [Object] = []
        for obj in self.objects.values {
            objects.append(obj)
        }
        return objects
    }

    func getAllTiles() -> [Tile] {
        var tiles: [Tile] = []
        for tl in self.tiles.values {
            tiles.append(tl)
        }
        return tiles
    }

    func getAllMapObjects() -> [MapObject] {
        var mapObjects: [MapObject] = []
        mapObjects = mapObjects + self.getAllObjects()
        mapObjects = mapObjects + self.getAllTiles()
        return mapObjects
    }

    // getter for MapObjects from TileCoordinate

    func getObjectsOn(_ coordinate: TileCoordinate) -> [Object] {
        var objects: [Object] = []
        if let ids = self.objectsPlacement[coordinate] {
            for id in ids {
                objects.append(self.objects[id]!)
            }
        }
        return objects
    }

    func getTileOn(_ coordinate: TileCoordinate) -> Tile? {
        var tile: Tile? = nil
        if let id = self.tilesPlacement[coordinate] {
            tile = self.tiles[id]
        }
        return tile
    }

    func getEventObjectsOn(_ coordinate: TileCoordinate) -> [EventObject] {
        var eventObjects: [EventObject] = []
        if let ids = self.eventsPlacement[coordinate] {
            for id in ids {
                eventObjects.append(self.events[id]!)
            }
        }
        return eventObjects
    }

    func getMapObjectsOn(_ coordinate: TileCoordinate) -> [MapObject] {
        var mapObjects: [MapObject] = []
        mapObjects = mapObjects + self.getObjectsOn(coordinate)
        mapObjects = mapObjects + self.getEventObjectsOn(coordinate)
        if let tile = self.getTileOn(coordinate) {
            mapObjects.append(tile)
        }
        return mapObjects
    }

    func getEventsOn(_ coordinate: TileCoordinate) -> [EventListener] {
        var events: [EventListener] = []
        let eventObjects = self.getEventObjectsOn(coordinate)
        for eventObject in eventObjects {
            events.append(eventObject.eventListener)
        }
        return events
    }

    // other getter's

    func getObjectBehavior(_ id: MapObjectId) -> EventListener? {
        return self.objects[id]?.behavior
    }

    func getObjectByName(_ name: String) -> Object? {
        for object in self.objects.values {
            if object.name == name {
                return object
            }
        }
        return nil
    }

    func getObjectCoordinateByName(_ name: String) -> TileCoordinate? {
        if let object = self.getObjectByName(name) {
            let objectId = object.id
            for placement in self.objectsPlacement {
                for id in placement.value {
                    if id == objectId {
                        return placement.key
                    }
                }
            }
        }
        return nil
    }

    func replaceObject(_ id: MapObjectId, departure: TileCoordinate, destination: TileCoordinate) {
        var arrayIndex: Int? = nil
        let objects = self.getObjectsOn(departure)
        for (index, object) in objects.enumerated() {
            if object.id == id {
                arrayIndex = index
                break
            }
        }

        if let i = arrayIndex {
            self.objectsPlacement[departure]?.remove(at: i)
            self.objectsPlacement[destination]?.append(id)
        } else {
            return
        }
    }
}
