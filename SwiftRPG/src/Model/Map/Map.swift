//
//  Map.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/02/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SpriteKit

public class Map {
    /// タイルシート
    private(set) var sheet: TileSheet? = nil
    
    /// マップオブジェクトの配置を保持しておくディクショナリ
    private var placement: Dictionary<TileCoordinate, [MapObject]> = [:]
    
    /// オブジェクトのみ保持するディクショナリ
    private var objects: Dictionary<TileCoordinate, [Object]> = [:]
    
    ///  コンストラクタ
    ///
    ///  - parameter mapName:     マップである JSON ファイルの名前
    ///  - parameter frameWidth:  フレームの幅
    ///  - parameter frameHeight: フレームの高さ
    ///
    ///  - returns:
    init?(mapName: String,
          frameWidth: CGFloat,
          frameHeight: CGFloat)
    {
        let parser: TiledMapJsonParser
        do {
            parser = try TiledMapJsonParser(fileName: mapName)
        } catch ParseError.IllegalJsonFormat {
            print("Invalid JSON format in \(mapName)")
            return nil
        } catch ParseError.JsonFileNotFound {
            print("JSON file \(mapName) is not found")
            return nil
        } catch {
            return nil
        }

        let tiles: Dictionary<TileCoordinate, Tile>
        var objects: Dictionary<TileCoordinate, [Object]>
        do {
            let cols, rows: Int
            (cols, rows) = try parser.getLayerSize()
            let tileProperties = try parser.getTileProperties()
            let tileSets = try parser.getTileSets()
            let collisionLayer = try parser.getInfoFromLayer(cols, layerTileRows: rows, kind: .COLLISION)
            let tileLayer = try parser.getInfoFromLayer(cols, layerTileRows: rows, kind: .TILE)
            let objectLayer = try parser.getInfoFromLayer(cols, layerTileRows: rows, kind: .OBJECT)
            tiles = try Tile.createTiles(rows,
                                         cols: cols,
                                         properties: tileProperties,
                                         tileSets: tileSets,
                                         collisionPlacement: collisionLayer,
                                         tilePlacement: tileLayer)
            objects = try Object.createObjects(tiles,
                                               properties: tileProperties,
                                               tileSets: tileSets,
                                               objectPlacement: objectLayer)
        } catch ParseError.InvalidValueError(let string) {
            print(string)
            return nil
        } catch ParseError.SwiftyJsonError(let errors) {
            for error in errors { print(error) }
            return nil
        } catch MapObjectError.FailedToGenerate(let string) {
            print(string)
            return nil
        } catch {
            return nil
        }

        // 主人公の作成
        let playerPosition = TileCoordinate(x: 10, y: 10)
        let player = Object(name: objectNameTable.PLAYER_NAME,
                            imageName: objectNameTable.PLAYER_IMAGE_DOWN,
                            position: TileCoordinate.getSheetCoordinateFromTileCoordinate(playerPosition),
                            images: objectNameTable.PLAYER_IMAGE_SET)
        if objects[playerPosition] == nil {
            objects[playerPosition] = [player]
        } else {
            objects[playerPosition]!.append(player)
        }

        let sheet = TileSheet(parser: parser,
                              frameWidth: frameWidth,
                              frameHeight: frameHeight,
                              tiles: tiles,
                              objects: objects)
        self.sheet = sheet!

        for (coordinate, tile) in tiles {
            self.placement[coordinate] = [tile]
        }

        for (coordinate, objectsOnTile) in objects {
            for objectOnTile in objectsOnTile {
                self.placement[coordinate]!.append(objectOnTile)
            }
        }

        self.objects = objects
    }

    func addSheetTo(scene: SKScene) {
        self.sheet?.addTo(scene)
    }

    ///  名前からオブジェクトを取得する
    ///
    ///  - parameter name: オブジェクト名
    ///
    ///  - returns: 取得したオブジェクト．存在しなければ nil
    func getObjectByName(name: String) -> Object? {
        for (_, mapObjects) in placement {
            for object in mapObjects {
                if let obj = object as? Object {
                    if obj.name == name { return obj }
                }
            }
        }
        return nil
    }

    func getObjectCoordinateByName(name: String) -> TileCoordinate? {
        for (coordinate, mapObjects) in placement {
            for object in mapObjects {
                if let obj = object as? Object {
                    if obj.name == name { return coordinate }
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
    func getEventsOn(coordinate: TileCoordinate) -> [EventListener] {
        var events: [EventListener] = []

        if let mapObjects = self.placement[coordinate] {
            for mapObject in mapObjects {
                for event in mapObject.events {
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
        let departure   = self.getObjectCoordinateByName(object.name)!
        let destination = TileCoordinate.getTileCoordinateFromSheetCoordinate(object.getRealTimePosition())
        
        var objectIndex: Int? = nil
        let mapObjects = self.placement[departure]
        for (index, mapObject) in mapObjects!.enumerate() {
            if let obj = mapObject as? Object {
                if obj.name == object.name {
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

    ///  オブジェクトのZ方向の位置を更新する
    func updateObjectsZPosition() {
        var objects: [(Object, CGFloat)] = []
        
        for objectsOnTile in self.objects.values {
            for object in objectsOnTile {
                objects.append((object, object.getRealTimePosition().y))
            }
        }
        
        // Y座標に基づいてオブジェクトを並べ替え，zPosition を更新する
        objects.sortInPlace { $0.1 > $1.1 }
        let base = zPositionTable.BASE_OBJECT_POSITION
        var incremental: CGFloat = 0.0
        for (obj, _) in objects {
            obj.setZPosition(base + incremental)
            incremental++
        }
    }
}