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

/// タイルセットの情報を保持する構造体
/// 1画像ファイル内のタイル群 = 1タイルセット に対応する
struct TileSetInfo {
    /// 画像ファイル名
    var imageName: String
    /// セット内のタイル数
    var count: Int
    /// 一番若いタイルID
    var firstTileID: Int
    /// タイルセット(画像ファイル)の横幅
    var imageWidth: Int
    /// タイルセット(画像ファイル)の縦幅
    var imageHeight: Int
    /// タイルセット内の各タイルの横幅
    var tileWidth: Int
    /// タイルセット内の各タイルの縦幅
    var tileHeight: Int
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
    func getTileSetsInfo() throws -> Dictionary<TileSetID, TileSetInfo> {
        var tileSetsInfo: Dictionary<TileSetID, TileSetInfo> = [:]
        if let tileSets = json["tilesets"].array {
            var tileSetID = 1
            for tileSet in tileSets {
                tileSetsInfo[tileSetID] = TileSetInfo(
                    imageName:   tileSet["image"].string!,
                    count:       tileSet["tilecount"].int!,
                    firstTileID: tileSet["firstgid"].int!,
                    imageWidth:  tileSet["imagewidth"].int!,
                    imageHeight: tileSet["imageheight"].int!,
                    tileWidth:   tileSet["tilewidth"].int!,
                    tileHeight:  tileSet["tileheight"].int!
                )
                tileSetID++
            }
            return tileSetsInfo
        } else {
            throw ParseError.SwiftyJsonError([json["tilesets"].error])
        }
    }
    
    
    ///  レイヤから得られる各タイルの情報を取得する
    ///
    ///  - parameter layerTileCols: レイヤーのタイル列数
    ///  - parameter layerTileRows: レイヤーのタイル行数
    ///
    ///  - throws: レイヤーが存在しない場合
    ///
    ///  - returns: タイル座標をキーとしたタイル情報のディクショナリ
    func getTileInfoArray(
        layerTileCols: Int,
        layerTileRows: Int
    ) throws -> Dictionary<TileCoordinate, TileInfo>
    {
        var tileInformations: Dictionary<TileCoordinate, TileInfo> = [:]
        
        if (layerTileCols < 1 || layerTileRows < 1) {
            throw ParseError.otherError("Layer size is invalid.")
        }
        
        if let
            tileIDLayer    = json["layers"][0]["data"].array,
            collisionLayer = json["layers"][1]["data"].array,
            objectIDLayer  = json["layers"][2]["data"].array
        {
            for (var y = 1; y <= layerTileCols; y++) {
                for (var x = 1; x <= layerTileRows; x++) {
                    let index = (layerTileCols - y) * layerTileRows + x - 1
                    
                    tileInformations[TileCoordinate(x: x, y: y)] = TileInfo(
                        tileID: tileIDLayer[index].int!,
                        hasCollision: collisionLayer[index].int! != 0 ? true : false,
                        objectID: objectIDLayer[index].int!
                    )
                }
            }
            
            return tileInformations
        } else {
            throw ParseError.SwiftyJsonError(
                [
                    json["layers"][0]["data"].error,
                    json["layers"][1]["data"].error,
                    json["layers"][2]["data"].error
                ])
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
    
    
    ///  タイルの画像を，タイルセット(1画像ファイル)から切り出し，返す
    ///
    ///  - parameter tileSetID: 対象タイルが含まれるタイルセットID
    ///  - parameter tileID:    対象タイルのタイルID
    ///
    ///  - throws:
    ///
    ///  - returns: タイル画像
    func cropTileImage(
        tileSetID: Int,
        tileID: Int,
        tileSetInformations: Dictionary<TileSetID, TileSetInfo>
    ) throws -> UIImage {
        if (tileSetInformations[tileSetID] == nil) {
            throw ParseError.otherError("存在しないタイルセットIDです")
        }
        let tileSetInfo = tileSetInformations[tileSetID]!
        let file_name   = tileSetInfo.imageName
        let tileWidth   = tileSetInfo.tileWidth
        let tileHeight  = tileSetInfo.tileHeight
        let tileSetRows = tileSetInfo.imageWidth / tileWidth
        let firstTileID = tileSetInfo.firstTileID
        var iTargetTileInSet: Int
        
        // ID は左上から順番
        // TODO: tileSet の中に tileID が含まれていない場合の validation
        if firstTileID >= tileID {
            iTargetTileInSet = firstTileID - tileID
        } else {
            iTargetTileInSet = tileID - 1
        }
        
        // 対象タイルの，タイルセット内における位置(行数，列数)を調べる
        let targetCol: Int
        let targetRow: Int
        if iTargetTileInSet == 0 {
            targetCol = 1
            targetRow = 1
        } else {
            targetRow = Int(iTargetTileInSet % tileSetRows) + 1
            targetCol = Int(iTargetTileInSet / tileSetRows) + 1
        }
        
        // 画像の切り抜き
        // TODO: nil の場合の validation
        let image = UIImage(named: file_name)
        let cropCGImageRef = CGImageCreateWithImageInRect(
            image!.CGImage,
            CGRectMake(CGFloat(tileWidth) * CGFloat(targetRow - 1),
                CGFloat(tileHeight) * CGFloat(targetCol - 1),
                CGFloat(tileWidth),
                CGFloat(tileHeight)))
        
        return UIImage(CGImage: cropCGImageRef!)
    }
}