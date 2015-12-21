//
//  TiledMapJsonParser.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/10/12.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit

enum ParseError: ErrorType {
    case JsonFileNotFound
    case IllegalJsonFormat
    case SwiftyJsonError([NSError?])
}

class TiledMapJsonParser {
    // タイル画像の大きさは決まってる
    // INT でいいのか？
    private let TILE_SIZE = Int(Tile.TILE_SIZE)
    private var layerTileCols: Int? = nil
    private var layerTileRows: Int? = nil

    struct TileData {
        var tileID: Int?
        var hasCollision: Bool?
        var objectID: Int?
    }

    private var tileData: [[TileData?]] = [[]]

    struct TileMap {
        var imageName: String
        var count: Int
        var firstGid: Int
        var mapWidth: Int
        var mapHeight: Int
        var tileWidth: Int
        var tileHeight: Int
    }

    private var tileMaps: Dictionary<Int, TileMap> = [:]
    private var tileProperties: Dictionary<Int, Dictionary<String, String?>> = [:]

    init(fileName: String) throws {
        var json: JSON = nil
        if let path: String? =
        NSBundle.mainBundle().pathForResource(fileName, ofType: "json"),
        fileHandle: NSFileHandle? = NSFileHandle(forReadingAtPath: path!),
        data: NSData = fileHandle!.readDataToEndOfFile() {
            json = JSON(data: data)
            if json.type != Type.Dictionary {
                throw ParseError.IllegalJsonFormat
            }
        } else {
            throw ParseError.JsonFileNotFound
        }

        // 各タイルマップの読み込み
        if let tileSets = json["tilesets"].array {
            var mapID = 1
            for tileSet in tileSets {
                let first_gid = tileSet["firstgid"].int!
                let tileCount = tileSet["tilecount"].int!
                // タイルマップを得る
                tileMaps[mapID] = TileMap(
                imageName: tileSet["image"].string!,
                count: tileCount,
                firstGid: first_gid,
                mapWidth: tileSet["imagewidth"].int!,
                mapHeight: tileSet["imageheight"].int!,
                tileWidth: tileSet["tilewidth"].int!,
                tileHeight: tileSet["tileheight"].int!
                )

                for id in first_gid ... first_gid + tileCount - 1 {
                    // TODO: validate
                    tileProperties[id] = ["mapID": mapID.description]
                }

                for (cor, properties) in tileSet["tileproperties"] {
                    for (property, value) in properties {
                        tileProperties[first_gid + Int(cor)!]![property] = value.string
                        // イベントはここで別の配列に格納する？
                    }
                }
                mapID++
            }
        } else {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }

        if let rows = json["height"].int,
        cols = json["width"].int {
            layerTileCols = cols
            layerTileRows = rows
        } else {
            ParseError.SwiftyJsonError([json["height"].error, json["width"].error])
        }

        // TODO: レイヤを順番ではなく名前で読み込み
        if let gids = json["layers"][0]["data"].array,
        collisions = json["layers"][1]["data"].array,
        obj_ids = json["layers"][2]["data"].array {
            // Initialize
            tileData = [[TileData?]](count: layerTileRows!,
                                     repeatedValue: [TileData?](
                                     count: layerTileCols!,
                                     repeatedValue: nil
                                     ))
            for (var y = 0; y < layerTileCols; y++) {
                for (var x = 0; x < layerTileRows; x++) {
                    let index = (layerTileCols! - 1 - y) * layerTileRows! + x

                    tileData[x][y] = TileData(
                    tileID: gids[index].int!,
                    // 0: 何も置かれていない
                    hasCollision: collisions[index].int! != 0 ? true : false,
                    objectID: obj_ids[index].int!
                    )
                }
            }
        } else {
            throw ParseError.SwiftyJsonError(
            [
                    json["layers"][0]["data"].error,
                    json["layers"][1]["data"].error,
                    json["layers"][2]["data"].error
            ])
        }
    }

    // タイルデータを返す
    func getTileData() -> [[TileData?]] {
        return tileData
    }

    func getTileProperties() -> Dictionary<Int, Dictionary<String, String?>> {
        return tileProperties
    }

    func getLayerSize() -> [Int] {
        // TODO: nil チェック
        return [layerTileCols!, layerTileRows!]
    }

    // 画像を読み込み画像データを返す
    // id は左上から順番(おそらく)
    func cropTileFromMap(mapID: Int, gid: Int) -> UIImage {
        let map = tileMaps[mapID]
        let file_name = map?.imageName
        let tileWidth = (map?.tileWidth)!
        let tileHeight = (map?.tileHeight)!
        let mapRows = (map?.mapWidth)! / tileWidth
        let firstGid = map?.firstGid
        var cropPosition: Int
        // TODO: map の中に gid が含まれていない場合の validation
        if firstGid >= gid {
            cropPosition = firstGid! - gid
        } else {
            cropPosition = gid - 1
        }

        let targetCol: Int
        let targetRow: Int
        if cropPosition == 0 {
            targetCol = 1
            targetRow = 1
        } else {
            targetRow = Int(cropPosition % mapRows) + 1
            targetCol = Int(cropPosition / mapRows) + 1
        }

        // TODO: nil の場合の validation
        let image = UIImage(named: file_name!)
        let cropCGImageRef = CGImageCreateWithImageInRect(
        image!.CGImage,
        CGRectMake(CGFloat(tileWidth) * CGFloat(targetRow - 1),
                   CGFloat(tileHeight) * CGFloat(targetCol - 1),
                   CGFloat(tileWidth),
                   CGFloat(tileHeight)))
        let cropImage = UIImage(CGImage: cropCGImageRef!)

        return cropImage
    }
}