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
    case otherError(String)
}

/// タイルの配置や種類の情報を記述したJSONファイルのパーサ
class TiledMapJsonParser {
    private var json : JSON = nil
    
    /// タイルサイズ
    private let TILE_SIZE = Int(Tile.TILE_SIZE)
    
    
    ///  コンストラクタ
    ///
    ///  - parameter fileName: パース対象のjsonファイル名
    init?(fileName: String) {
        if let path: String? = NSBundle.mainBundle().pathForResource(fileName, ofType: "json"),
            fileHandle: NSFileHandle? = NSFileHandle(forReadingAtPath: path!),
            data: NSData = fileHandle!.readDataToEndOfFile() {
                self.json = JSON(data: data)
                if self.json.type != Type.Dictionary {
                    // JSON フォーマットが正しくない
                    return nil
                }
        } else {
            // JSON ファイルへのパスがまちがっている
            return nil
        }
    }
    
    
    ///  タイルセットの各情報を取得する
    ///
    ///  - throws: 失敗時
    ///
    ///  - returns: タイルセットの情報．画像ファイル名やセット内のタイル数等．詳しくは TileSetInfo を参照
    func getTileSets() throws -> Dictionary<TileSetID, TileSet> {
        var tileSets: Dictionary<TileSetID, TileSet> = [:]
        if let tileSetsJson = json["tilesets"].array {
            var tileSetID = 1
            for tileSetJson in tileSetsJson {
                tileSets[tileSetID] = TileSet(
                    id: tileSetID,
                    imageName: tileSetJson["image"].string!,
                    nTile: tileSetJson["tilecount"].int!,
                    firstTileID: tileSetJson["firstgid"].int!,
                    width: tileSetJson["imagewidth"].int!,
                    height: tileSetJson["imageheight"].int!,
                    tileWidth: tileSetJson["tilewidth"].int!,
                    tileHeight: tileSetJson["tileheight"].int!
                )
                tileSetID++
            }
            return tileSets
        } else {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }
    }
    
    
    ///  各タイルのプロパティを取得する
    ///
    ///  - throws: 失敗時
    ///
    ///  - returns: プロパティのディクショナリ
    func getTileProperties() throws -> Dictionary<TileID, TileProperty> {
        var properties: Dictionary<TileID, TileProperty> = [:]
        
        if let tileSets = json["tilesets"].array {
            var tileSetID = 1
            for tileSet in tileSets {
                let firstTileID = tileSet["firstgid"].int!
                let nTileInSet  = tileSet["tilecount"].int!
                
                // tileSet 内の全 tile について loop
                for tileID in firstTileID ... firstTileID + nTileInSet -  1 {
                    properties[tileID] = [
                        "tileSetID": tileSetID.description,
                        "tileSetName": tileSet["name"].string!
                    ]
                }
                
                // その他のプロパティを保持
                for (cor, tileproperties) in tileSet["tileproperties"] {
                    for (property, value) in tileproperties {
                        let tileID = firstTileID + Int(cor)!
                        if !(properties[tileID] == nil) {
                            properties[tileID]![property] = value.string
                        } else {
                            throw ParseError.otherError("Invalid tile id in tile properties.")
                        }
                    }
                }
                tileSetID++
            }
            return properties
        } else {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }
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
    
    
    ///  レイヤから得られる情報を返す
    ///
    ///  - parameter layerTileCols: レイヤ上のタイルの行数
    ///  - parameter layerTileRows: レイヤ上のタイルの列数
    ///  - parameter kind:          読み込むレイヤの種類
    ///
    ///  - throws:
    ///
    ///  - returns: 
    func getInfoFromLayer(
        layerTileCols: Int,
        layerTileRows: Int,
        kind: LAYER
    ) throws -> Dictionary<TileCoordinate, Int> {
        var info: Dictionary<TileCoordinate, Int> = [:]
        
        if (layerTileCols < 1 || layerTileRows < 1) {
            throw ParseError.otherError("Layer size is invalid.")
        }
        
        if let layer = json["layers"][kind.rawValue]["data"].array {
            for (var y = 1; y <= layerTileCols; y++) {
                for (var x = 1; x <= layerTileRows; x++) {
                    let index = (layerTileCols - y) * layerTileRows + x - 1
                    info[TileCoordinate(x: x, y: y)] = layer[index].int!
                }
            }
            return info
        } else {
            let err = json["layers"][kind.rawValue]["data"].error
            throw ParseError.SwiftyJsonError([err])
        }
    }
    
    
    ///  レイヤーのサイズを取得する
    ///
    ///  - throws: レイヤー情報が読み込めなかった場合
    ///
    ///  - returns: [ 行数, 列数 ]
    func getLayerSize() throws -> (cols: Int, rows: Int) {
        do {
            let layerTileCols: Int
            let layerTileRows: Int
            
            if let
                rows = json["height"].int,
                cols = json["width"].int {
                    layerTileCols = cols
                    layerTileRows = rows
            } else {
                throw ParseError.SwiftyJsonError([json["height"].error, json["width"].error])
            }
            
            return (layerTileCols, layerTileRows)
        } catch {
            throw error
        }
    }
}