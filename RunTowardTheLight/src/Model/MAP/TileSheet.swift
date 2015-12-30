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

class TileSheet {
    // sheet
    private let sheet_: SKSpriteNode
    private let sheetTileRows_: Int
    private let sheetTileCols_: Int
    // frame
    private let frame_: [SKShapeNode]
    private let frameWeightWidth_: CGFloat
    private let frameWeightHeight_: CGFloat
    // view
    private let viewTileRows_: Int
    private let viewTileCols_: Int

    private var tileArray_: [Tile?] = []
    private var objectArray_: [String:Object] = [:]

    private var tileData: [[TiledMapJsonParser.TileData?]]

    enum DIRECTION {
        case UP, DOWN, LEFT, RIGHT
    }

    init(jsonFileName: String, frameWidth: CGFloat, frameHeight: CGFloat) {

        var parser: TiledMapJsonParser! = nil
        do {
            parser = try TiledMapJsonParser(fileName: jsonFileName)
        } catch ParseError.JsonFileNotFound {
            print("Json file not found")
        } catch ParseError.IllegalJsonFormat {
            print("Illegal json format")
        } catch ParseError.SwiftyJsonError(let errors) {
            for error in errors {
                print(error)
            }
        } catch {
            print("erroe")
        }

        tileData = parser.getTileData()
        let tileProperties = parser.getTileProperties()
        sheetTileCols_ = parser.getLayerSize()[0]
        sheetTileRows_ = parser.getLayerSize()[1]

        // Create frame
        viewTileRows_ = Int(frameWidth / Tile.TILE_SIZE)
        viewTileCols_ = Int(frameHeight / Tile.TILE_SIZE)
        frameWeightWidth_ = (frameWidth - CGFloat(viewTileRows_ * Int(Tile.TILE_SIZE))) / 2
        frameWeightHeight_ = (frameHeight - CGFloat(viewTileCols_ * Int(Tile.TILE_SIZE))) / 2

        var horizonalPoints = [CGPointMake(0.0, 0.0), CGPointMake(frameWidth, 0)]
        var verticalPoints = [CGPointMake(0.0, 0.0), CGPointMake(0, frameHeight)]
        let horizonalLine = SKShapeNode(points: &horizonalPoints, count: horizonalPoints.count)
        horizonalLine.lineWidth = frameWeightHeight_ * 2
        horizonalLine.strokeColor = UIColor.blackColor()
        horizonalLine.zPosition = 10
        let verticalLine = SKShapeNode(points: &verticalPoints, count: verticalPoints.count)
        verticalLine.lineWidth = frameWeightWidth_ * 2
        verticalLine.strokeColor = UIColor.blackColor()
        verticalLine.zPosition = 10

        let underLine = horizonalLine.copy() as! SKShapeNode
        underLine.position = CGPointMake(0, 0)
        let upperLine = horizonalLine.copy() as! SKShapeNode
        upperLine.position = CGPointMake(0, frameHeight)
        let leftLine = verticalLine.copy() as! SKShapeNode
        leftLine.position = CGPointMake(0, 0)
        let rightLine = verticalLine.copy() as! SKShapeNode
        rightLine.position = CGPointMake(frameWidth, 0)

        frame_ = [underLine, upperLine, leftLine, rightLine]


        // Create sheet
        sheet_ = SKSpriteNode(color: UIColor.whiteColor(),
                              size: CGSizeMake(CGFloat(sheetTileRows_) * Tile.TILE_SIZE,
                                               CGFloat(sheetTileCols_) * Tile.TILE_SIZE))
        sheet_.position = CGPointMake(frameWeightWidth_, frameWeightHeight_)
        sheet_.anchorPoint = CGPointMake(0.0, 0.0)

        for (var x = 1; x <= Int(sheetTileRows_); x++) {
            for (var y = 1; y <= Int(sheetTileCols_); y++) {
                let data = tileData[x - 1][y - 1]

                // タイルを作成する
                let tile = Tile(
                coordinate: TileCoordinate(x: x, y: y),
                event: nil
                )

                // 画像を付加する
                let gid = Int((data?.tileID)!)
                let map_id = Int(tileProperties[gid]!["mapID"]!!)
                let tile_image = parser.cropTileFromMap(map_id!, gid: gid)
                tile.setImageWithUIImage(tile_image)

                // 当たり判定
                let hasCollision = data?.hasCollision!
                if hasCollision! {
                    tile.setCollision()
                }

                // イベント
                let action = tileProperties[gid]!["event"]
                if (action != nil) {
                    //let file_name = tile_sets[gid]!["event_class"]!
                    let events = EventDispatcher<AnyObject?>()
                    events.add(GameSceneEvent.events[action!!]!(nil))
                    tile.setEvent(events)
                }

                tile.addTo(sheet_)
                tileArray_.append(tile)
            }
        }

        // すべてのタイル描画後にやらないとかぶってしまう
        for (var x = 1; x <= Int(sheetTileRows_); x++) {
            for (var y = 1; y <= Int(sheetTileCols_); y++) {
                let data = tileData[x - 1][y - 1]

                // オブジェクト判定
                let obj_id = Int((data?.objectID)!)
                if (obj_id != 0) {
                    let map_id = Int(tileProperties[obj_id]!["mapID"]!!)

                    // 配置
                    let obj_image = parser.cropTileFromMap(map_id!, gid: obj_id)
                    self.placementObjectOnTileWithUIImage("name",
                                                          image: obj_image,
                                                          coordinate: TileCoordinate(x: x, y: y))

                    // 当たり判定
                    // TODO: 本来はタイルではなくオブジェクトに当たり判定をつける
                    let hasCollision = tileProperties[obj_id]!["collision"]
                    if hasCollision != nil {
                        if hasCollision! == "1" {
                            getTile(TileCoordinate(x: x, y: y))?.setCollision()
                        }
                    }

                    // obj のイベントは全てこれで良いか？多分良くない...
                    // 落ちてるもののイベントだってあるだろう．現状は，当たり判定がある obj 限定
                    let obj_action = tileProperties[obj_id]!["event"]
                    if (obj_action != nil) {
                        let events = EventDispatcher<AnyObject?>()
                        events.add(GameSceneEvent.events[obj_action!!]!(nil))
                        // 周囲四方向のタイルにイベントを設置
                        // 各方向に違うイベントが設置できない＼(^o^)／
                        // タイルに設置するよりも，別レイヤーとしてオブジェクトの周りにおいたほうが良いかも
                        getTile(TileCoordinate(x: x - 1, y: y))?.setEvent(events)
                        getTile(TileCoordinate(x: x + 1, y: y))?.setEvent(events)
                        getTile(TileCoordinate(x: x, y: y - 1))?.setEvent(events)
                        getTile(TileCoordinate(x: x, y: y + 1))?.setEvent(events)
                    }
                }
            }
        }
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
        for line in frame_ {
            scene.addChild(line)
        }
    }

    ///  オブジェクトの向きを取得する
    ///
    ///  - parameter objectName: オブジェクト名
    ///
    ///  - returns: オブジェクトの向き
    func getPlayerDirection(objectName: String) -> TileSheet.DIRECTION {
        let object: Object = objectArray_[objectName]!
        return object.getDirection()
    }

    ///  オブジェクトの速さを取得する
    ///
    ///  - parameter objectName: オブジェクト名
    ///
    ///  - returns: オブジェクトの速さ
    func getPlayerSpeed(objectName: String) -> CGFloat {
        let object: Object = objectArray_[objectName]!
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
        CGPointMake(frameWeightWidth_ + 1, frameWeightHeight_ + 1)
        )
        // 原点から見て画面端のタイル
        let max_x = sheetOrigin.getX() + viewTileRows_ - 1
        let max_y = sheetOrigin.getY() + viewTileCols_ - 1

        // スクロールするか？(プレイヤーの現在位置チェック)
        if (position.getX() >= max_x
            || position.getY() >= max_y
            || position.getX() <= sheetOrigin.getX()
            || position.getY() <= sheetOrigin.getY()) {
            var direction: TileSheet.DIRECTION

            if (position.getX() >= max_x) {
                direction = TileSheet.DIRECTION.RIGHT
            } else if (position.getY() >= max_y) {
                direction = TileSheet.DIRECTION.UP
            } else if (position.getX() <= sheetOrigin.getX()) {
                direction = TileSheet.DIRECTION.LEFT
            } else if (position.getY() <= sheetOrigin.getY()) {
                direction = TileSheet.DIRECTION.DOWN
            } else {
                // WARNING: won't use
                direction = TileSheet.DIRECTION.UP
            }

            var deltaX: CGFloat = 0
            var deltaY: CGFloat = 0
            switch (direction) {
                case TileSheet.DIRECTION.UP:
                    deltaX = 0
                    deltaY = -(CGFloat(viewTileCols_ - 1) * Tile.TILE_SIZE)
                case TileSheet.DIRECTION.DOWN:
                    deltaX = 0
                    deltaY = CGFloat(viewTileCols_ - 1) * Tile.TILE_SIZE
                case TileSheet.DIRECTION.LEFT:
                    deltaX = CGFloat(viewTileRows_ - 1) * Tile.TILE_SIZE
                    deltaY = 0
                case TileSheet.DIRECTION.RIGHT:
                    deltaX = -(CGFloat(viewTileRows_ - 1) * Tile.TILE_SIZE)
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

    // タイルにオブジェクトを追加・配置する
    func placementObjectOnTileWithUIImage(name: String, image: UIImage, coordinate: TileCoordinate) {
        let object = Object(name: name,
                            imageData: image,
                            position: getTileCenterPosition(coordinate))
        object.addTo(sheet_)
        objectArray_ = [name: object]
    }

    func placementObjectOnTileWithName(name: String, image_name: String, coordinate: TileCoordinate) {
        let object = Object(name: name,
                            imageName: image_name,
                            position: getTileCenterPosition(coordinate))
        object.addTo(sheet_)
        objectArray_ = [name: object]
    }

    // フレーム上かどうか判定する
    func isOnFrame(position: CGPoint) -> Bool {
        if (position.x <= frameWeightWidth_
            || position.x >= frameWeightWidth_ + CGFloat(viewTileRows_) * Tile.TILE_SIZE
            || position.y <= frameWeightHeight_
            || position.y >= frameWeightHeight_ + CGFloat(viewTileCols_) * Tile.TILE_SIZE
        ) {
            return true
        } else {
            return false
        }
    }

    // オブジェクトの位置を取得する
    // WARNING : obj は "シート上の" position. sheet の position は別
    func getObjectTileCoordinateBy(name: String) -> TileCoordinate? {
        return getTileCoordinateNearOnSheet((objectArray_[name]?.getPosition())!)
    }

    func getObjectPosition(name: String) -> CGPoint {
        return (objectArray_[name]?.getPosition())!
    }

    // タイルの通行可否を取得する
    func canPassTile(coordinate: TileCoordinate) -> Bool? {
        let hasCollision = tileData[coordinate.getX() - 1][coordinate.getY() - 1]!.hasCollision!
        if hasCollision {
            return false
        } else {
            return getTile(coordinate)?.canPass()
        }
    }

    func getActionTo(objectName: String, to: TileCoordinate) -> Array<SKAction> {
        let object: Object = objectArray_[objectName]!
        let destination = getTileCenterPosition(to)
        return object.getActionTo(destination)
    }

    func isEventOn(coordinate: TileCoordinate) -> EventDispatcher<AnyObject?>? {
        return getTile(coordinate)?.getEvent()
    }

    func moveObject(objectName: String, actions: Array<SKAction>, callback: () -> Void) {
        let object: Object = objectArray_[objectName]!
        object.runAction(actions, callback: callback)
    }

    // タッチされた位置に最も近いタイルの中心座標を返す
    func getTilePositionNear(pointOnScreen: CGPoint) -> CGPoint {
        return getTileCenterPosition(getTileCoordinateNear(pointOnScreen))
    }

    // 画面上の座標に最も近い，タイル位置を返す
    // ASSERT: 謎の「+1」
    func getTileCoordinateNear(pointOnScreen: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor(
                                     (pointOnScreen.x - sheet_.position.x) / CGFloat(Tile.TILE_SIZE) + 1)),
                              y: Int(floor(
                                     (pointOnScreen.y - sheet_.position.y) / CGFloat(Tile.TILE_SIZE) + 1)))
    }

    private func getTileCoordinateNearOnSheet(pointOnScreen: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor(pointOnScreen.x / CGFloat(Tile.TILE_SIZE) + 1)),
                              y: Int(floor(pointOnScreen.y / CGFloat(Tile.TILE_SIZE) + 1)))
    }

    // 指定したタイルの中心の座標を返す
    func getTileCenterPosition(coordinate: TileCoordinate) -> CGPoint {
        return CGPointMake(CGFloat(coordinate.getX()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2,
                           CGFloat(coordinate.getY()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2)
    }

    // タイルへアクセスする
    func getTile(coordinate: TileCoordinate) -> Tile? {
        let index = tileArray_.indexOf() {
            $0!.isOn(coordinate) == true
        }
        if index == nil {
            return nil
        } else {
            return tileArray_[index!]
        }
    }
}
