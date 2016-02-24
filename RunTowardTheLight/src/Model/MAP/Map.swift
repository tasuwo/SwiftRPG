//
//  Map.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

public class Map {
    /// タイルシート
    private var sheet: TileSheet? = nil
    
    /// オブジェクトの配置を保持しておくディクショナリ
    private var placement: Dictionary<TileCoordinate, [MapObject]> = [:]
    
    ///  コンストラクタ
    ///
    ///  - parameter mapName:     マップである JSON ファイルの名前
    ///  - parameter frameWidth:  フレームの幅
    ///  - parameter frameHeight: フレームの高さ
    ///
    ///  - returns:
    init?(
        mapName: String,
        frameWidth: CGFloat,
        frameHeight: CGFloat
    ) {
        if let parser = TiledMapJsonParser(fileName: mapName) {
            do {
                let cols, rows: Int
                (cols, rows) = try parser.getLayerSize()
                
                // タイルの生成
                let tiles = try Tile.createTiles(
                    rows,
                    cols:       cols,
                    properties: try parser.getTileProperties(),
                    tileSets:   try parser.getTileSets(),
                    collisionPlacement:
                        try parser.getInfoFromLayer(
                                cols,
                                layerTileRows: rows,
                                kind: TiledMapJsonParser.LAYER.COLLISION),
                    tilePlacement:
                        try parser.getInfoFromLayer(
                                cols,
                                layerTileRows: rows,
                                kind: TiledMapJsonParser.LAYER.TILE))
                
                
                // オブジェクトの生成
                let objects = try Object.createObjects(
                    tiles,
                    properties: try parser.getTileProperties(),
                    tileSets: try parser.getTileSets(),
                    objectPlacement: try parser.getInfoFromLayer(
                        cols,
                        layerTileRows: rows,
                        kind: TiledMapJsonParser.LAYER.OBJECT))
                
                // シートの生成
                let sheet = TileSheet(
                    parser: parser,
                    frameWidth: frameWidth,
                    frameHeight: frameHeight,
                    tiles: tiles,
                    objects: objects
                )
                self.sheet = sheet!
                
                // 主人公の配置
                let player = Object(
                    name: objectNameTable.PLAYER_NAME,
                    imageName: objectNameTable.PLAYER_IMAGE_DOWN,
                    position: TileCoordinate.getSheetCoordinateFromTileCoordinate(TileCoordinate(x: 10, y: 10)),
                    images: objectNameTable.PLAYER_IMAGE_SET)
                self.sheet!.addObjectToSheet(player)
                
                for (coordinate, tile) in tiles {
                    self.placement[coordinate] = [tile]
                }
                
                for (coordinate, objects) in objects {
                    self.placement[coordinate]!.append(objects)
                }
                
                self.placement[TileCoordinate(x: 10, y: 10)]?.append(player)
            } catch ParseError.IllegalJsonFormat {
                print("Json 形式が正しくありません")
            } catch ParseError.JsonFileNotFound {
                print("JSON ファイルが見つかりません")
            } catch ParseError.otherError(let str) {
                print(str)
            } catch ParseError.SwiftyJsonError(let errors) {
                for error in errors {
                    print(error)
                }
            } catch {
                print("その他のエラー")
            }
        } else {
            print("パーサの初期化失敗")
        }
    }
    
    
    func getSheet() -> TileSheet? {
        return self.sheet
    }
    
    
    func addSheetTo(scene: SKScene) {
        self.sheet?.addTo(scene)
    }
    
    
    ///  名前からオブジェクトを取得する
    ///
    ///  - parameter name: オブジェクト名
    ///
    ///  - returns: 取得したオブジェクト．存在しなければ nil
    func getObjectByName(name: String) -> (coordinate: TileCoordinate, object: Object)? {
        for (coordinate, mapObjects) in placement {
            for object in mapObjects {
                if let obj = object as? Object {
                    if obj.getName() == name { return (coordinate, obj) }
                }
            }
        }
        return nil
    }
    
    
    ///  配置されたオブジェクトを取得する
    ///
    ///  - parameter coordinate: タイル座標
    ///
    ///  - returns: 配置されたオブジェクト群
    func getMapObjectsOn(coordinate: TileCoordinate) -> [MapObject]? {
        return self.placement[coordinate]
    }
    
    
    ///  配置されたイベントを取得する
    ///
    ///  - parameter coordinate: イベントを取得するタイル座標
    ///
    ///  - returns: 取得したイベント群
    func getEventsOn(coordinate: TileCoordinate) -> [EventDispatcher<Any>] {
        var events: [EventDispatcher<Any>] = []
        
        if let mapObjects = self.placement[coordinate] {
            for mapObject in mapObjects {
                if let event = mapObject.event {
                    if event.hasListener() {
                        events.append(event)
                    }
                    events.append(event)
                }
            }
        }
        
        return events
    }
    
    
    ///  タイル座標の通行可否を判定する
    ///
    ///  - parameter coordinate: 判定対象のタイル座標
    ///
    ///  - returns: 通行可なら true, 通行不可なら false
    func canPass(coordinate: TileCoordinate) -> Bool {
        if let objects = self.placement[coordinate] {
            for object in objects {
                if object.hasCollision { return false }
            }
        }
        return true
    }
    
    
    ///  オブジェクトの位置情報を，実際のSKSpriteNodeの位置から更新する
    ///
    ///  - parameter object:        更新対象のオブジェクト
    func updateObjectPlacement(object: Object) {
        let departure: TileCoordinate
        (departure, _) = self.getObjectByName(object.getName())!
        let destination: TileCoordinate
        destination = TileCoordinate.getTileCoordinateFromSheetCoordinate(object.getRealTimePosition())
        
        var objectIndex: Int? = nil
        let mapObjects = self.placement[departure]
        for (index, mapObject) in mapObjects!.enumerate() {
            if let obj = mapObject as? Object {
                if obj.getName() == object.getName() {
                    objectIndex = index
                    break
                }
            }
        }
        
        if objectIndex == nil { return }
        self.placement[departure]!.removeAtIndex(objectIndex!)
        self.placement[destination]!.append(object)
        print(destination.description)
    }
}