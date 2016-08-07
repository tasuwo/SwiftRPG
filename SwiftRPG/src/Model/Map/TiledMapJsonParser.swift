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
    case InvalidValueError(String)
}

/// タイルの配置や種類の情報を記述したJSONファイルのパーサ
class TiledMapJsonParser {
    private var json : JSON = nil
    
    /// タイルサイズ
    private let TILE_SIZE = Int(Tile.TILE_SIZE)

    ///  コンストラクタ
    ///
    ///  - throws: JsonFileNotFound, IllegalJsonFormat
    ///
    ///  - parameter fileName: パース対象のjsonファイル名
    init(fileName: String) throws {
        let path: String? = NSBundle.mainBundle().pathForResource(fileName, ofType: "json")
        if path == nil {
            throw ParseError.JsonFileNotFound
        }

        let fileHandle: NSFileHandle? = NSFileHandle(forReadingAtPath: path!)
        if fileHandle == nil {
            throw ParseError.JsonFileNotFound
        }

        let data: NSData = fileHandle!.readDataToEndOfFile()

        self.json = JSON(data: data)
        if self.json.type != Type.Dictionary {
            throw ParseError.IllegalJsonFormat
        }
    }

    ///  タイルセットの各情報を取得する
    ///
    ///  - throws: SwiftyJsonError
    ///
    ///  - returns: タイルセットの情報．画像ファイル名やセット内のタイル数等．詳しくは TileSetInfo を参照
    func getTileSets() throws -> Dictionary<TileSetID, TileSet> {
        var tileSets: Dictionary<TileSetID, TileSet> = [:]

        let tileSetsJson = json["tilesets"].array
        if tileSetsJson == nil {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }

        var tileSetID = 1
        for tileSetJson in tileSetsJson! {
            tileSets[tileSetID] = TileSet(id: tileSetID,
                                          imageName: tileSetJson["image"].string!,
                                          nTile: tileSetJson["tilecount"].int!,
                                          firstTileID: tileSetJson["firstgid"].int!,
                                          width: tileSetJson["imagewidth"].int!,
                                          height: tileSetJson["imageheight"].int!,
                                          tileWidth: tileSetJson["tilewidth"].int!,
                                          tileHeight: tileSetJson["tileheight"].int!)
            tileSetID += 1
        }
        return tileSets
    }

    ///  各タイルのプロパティを取得する
    ///
    ///  - throws: SwiftyJsonError, otherError
    ///
    ///  - returns: プロパティのディクショナリ
    func getTileProperties() throws -> Dictionary<TileID, TileProperty> {
        var properties: Dictionary<TileID, TileProperty> = [:]

        let tileSets = json["tilesets"].array
        if tileSets == nil {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }

        var tileSetID = 1
        for tileSet in tileSets! {
            /// tileSet 内の最初のタイルの gid
            let firstTileID = tileSet["firstgid"].int
            /// tileSet 内に存在するタイルの数
            let nTileInSet  = tileSet["tilecount"].int
            if firstTileID == nil || nTileInSet == nil {
                throw ParseError.SwiftyJsonError([tileSet["firstgid"].error, tileSet["tilecount"].error])
            }

            // tileSet 内の各タイルについて，そのプロパティに tileSet の情報を追加する
            for tileID in firstTileID! ... firstTileID! + nTileInSet! -  1 {
                properties[tileID] = [
                    "tileSetID": tileSetID.description,
                    "tileSetName": tileSet["name"].string!
                ]
            }

            // 各タイル毎にその他のプロパティを保持
            if tileSet["tileproperties"] == nil {
                throw ParseError.SwiftyJsonError([tileSet["tileproperties"].error])
            }
            for (cor, tileproperties) in tileSet["tileproperties"] {
                for (property, value) in tileproperties {
                    let tileID = firstTileID! + Int(cor)!
                    if properties[tileID] != nil {
                        properties[tileID]![property] = value.string
                    } else {
                        throw ParseError.InvalidValueError("TileID is not found in properties")
                    }
                }
            }
            tileSetID += 1
        }
        return properties
    }

    ///  レイヤーの種類を表す enum 型
    ///
    ///  - TILE:      タイル情報
    ///  - COLLISION: 当たり判定情報
    ///  - OBJECT:    オブジェクト情報
    enum LAYER: Int {
        case TILE = 0
        case COLLISION = 1
        case OBJECT = 2
    }

    ///  レイヤから得られる情報(タイルの配置情報)を返す
    ///
    ///  - parameter layerTileCols: レイヤ上のタイルの行数
    ///  - parameter layerTileRows: レイヤ上のタイルの列数
    ///  - parameter kind:          読み込むレイヤの種類
    ///
    ///  - throws: SwiftyJsonError, otherError
    ///
    ///  - returns: レイヤ情報(タイル座標とタイルIDの組)
    func getInfoFromLayer(
        layerTileCols: Int,
        layerTileRows: Int,
        kind: LAYER
    ) throws -> Dictionary<TileCoordinate, Int> {
        var info: Dictionary<TileCoordinate, Int> = [:]
        
        if (layerTileCols < 1 || layerTileRows < 1) {
            throw ParseError.InvalidValueError("Invalid layer size: cols or rows is fewer than 1")
        }
        
        let layer = json["layers"][kind.rawValue]["data"].array
        if layer == nil {
            throw ParseError.SwiftyJsonError([json["layers"][kind.rawValue]["data"].error])
        }

        for y in 1 ..< layerTileCols+1 {
            for x in 1 ..< layerTileRows+1 {
                let index = (layerTileCols - y) * layerTileRows + x - 1
                if layer![index].int == nil {
                    throw ParseError.SwiftyJsonError([layer![index].error])
                }
                info[TileCoordinate(x: x, y: y)] = layer![index].int!
            }
        }

        return info
    }

    ///  レイヤーのサイズを取得する
    ///
    ///  - throws: SwiftyJsonError
    ///
    ///  - returns: [ 行数, 列数 ]
    func getLayerSize() throws -> (cols: Int, rows: Int) {
        let layerTileCols = json["height"].int
        let layerTileRows = json["width"].int
        if layerTileCols == nil || layerTileRows == nil {
            throw ParseError.SwiftyJsonError([json["height"].error, json["width"].error])
        }

        return (layerTileCols!, layerTileRows!)
    }
}
