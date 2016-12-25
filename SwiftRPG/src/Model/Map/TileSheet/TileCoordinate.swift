//
//  TileCoordinate.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

/// タイル座標．座標には以下の三種類がある
/// - タイル座標 TileCoordinate   : タイル
/// - 画面座標   ScreenCoordinate : 画面左下を原点とした相対座標
/// - シート座標 SheetCoordinate  : シート左下を原点とした相対座標
class TileCoordinate: Hashable {
    let x: Int
    let y: Int

    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
    
    ///  タッチされた位置に最も近いタイルの中心の画面上の座標を返す
    ///
    ///  - parameter sheetPosition:   タイルシートの位置
    ///  - parameter touchedPosition: タッチされた座標
    ///
    ///  - returns: タイルの中心の画面上の座標
    class func getSheetCoordinateOfTouchedTile(_ sheetPosition: CGPoint, touchedPosition: CGPoint) -> CGPoint {
        return TileCoordinate.getSheetCoordinateFromTileCoordinate(
            TileCoordinate.getTileCoordinateFromScreenCoordinate(sheetPosition, screenCoordinate: touchedPosition)
        )
    }

    ///  画面座標をタイル座標に変換する
    ///
    ///  - parameter sheetPosition:   タイルシートの位置
    ///  - parameter touchedPosition: タッチされた座標
    ///
    ///  - returns: 最も近いタイルのタイル座標
    class func getTileCoordinateFromScreenCoordinate(_ sheetPosition: CGPoint, screenCoordinate: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor((screenCoordinate.x - sheetPosition.x) / CGFloat(Tile.TILE_SIZE) + 1)),
                              y: Int(floor((screenCoordinate.y - sheetPosition.y) / CGFloat(Tile.TILE_SIZE) + 1)))
    }

    ///  シート座標をタイル座標に変換する
    ///
    ///  - parameter sheetPosition: シート座標
    ///
    ///  - returns: タイル座標
    class func getTileCoordinateFromSheetCoordinate(_ sheetCoordinate: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor(sheetCoordinate.x / CGFloat(Tile.TILE_SIZE) + 1)),
                              y: Int(floor(sheetCoordinate.y / CGFloat(Tile.TILE_SIZE) + 1)))
    }

    class func getSheetCoordinateFromScreenCoordinate(_ sheetPosition: CGPoint, screenCoordinate: CGPoint) -> CGPoint {
        return CGPoint(x: screenCoordinate.x + sheetPosition.x, y: screenCoordinate.y + sheetPosition.y)
    }

    ///  タイル座標をシート座標に変換する
    ///  シート座標は，該当タイルの中心の値を返す
    ///
    ///  - parameter coordinate: タイル座標
    ///
    ///  - returns: シート座標
    class func getSheetCoordinateFromTileCoordinate(_ tileCoordinate: TileCoordinate) -> CGPoint {
        return CGPoint(x: CGFloat(tileCoordinate.x) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2,
                           y: CGFloat(tileCoordinate.y) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2)
    }

    // MARK: - Hashable

    var hashValue : Int {
        get {
            return "\(self.x),\(self.y)".hashValue
        }
    }
    
    var description : String {
        get {
            return "\(self.x),\(self.y)"
        }
    }
}

// MARK: - Equatable

func ==(lhs: TileCoordinate, rhs: TileCoordinate) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

func -(lhs: TileCoordinate, rhs: TileCoordinate) -> TileCoordinate {
    return TileCoordinate(x: lhs.x-rhs.x, y: lhs.y-rhs.y)
}

func +(lhs: TileCoordinate, rhs: TileCoordinate) -> TileCoordinate {
    return TileCoordinate(x: lhs.x+rhs.x, y: lhs.y+rhs.y)
}
