//
//  TileCoordinate.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

// MARK: - Equatable
func ==(lhs: TileCoordinate, rhs: TileCoordinate) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

/// タイル座標
class TileCoordinate: Hashable {
    private let x: Int
    private let y: Int
    
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
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    ///  X座標のgetter
    ///
    ///  - returns: X座標
    func getX() -> Int {
        return self.x
    }

    
    ///  Y座標のgetter
    ///
    ///  - returns: Y座標
    func getY() -> Int {
        return self.y
    }
    

    ///  座標の比較用関数
    ///
    ///  - parameter coordinate: 比較対象の座標
    ///
    ///  - returns: 比較結果．等しければ true，そうでなければ false
    func isEqual(coordinate: TileCoordinate) -> Bool {
        return (x == coordinate.getX() &&
                y == coordinate.getY())
    }
    
    // 座標には三種類ある
    // - タイル座標 TileCoordinate   : タイル
    // - 画面座標   ScreenCoordinate : 画面左下を原点とした相対座標
    // - シート座標 SheetCoordinate  : シート左下を原点とした相対座標
    
    
    ///  タッチされた位置に最も近いタイルの中心の画面上の座標を返す
    ///
    ///  - parameter sheetPosition:   タイルシートの位置
    ///  - parameter touchedPosition: タッチされた座標
    ///
    ///  - returns: タイルの中心の画面上の座標
    class func getSheetCoordinateOfTouchedTile(
        sheetPosition: CGPoint,
        touchedPosition: CGPoint
    ) -> CGPoint {
        return TileCoordinate.getSheetCoordinateFromTileCoordinate(
            TileCoordinate.getTileCoordinateFromScreenCoordinate(sheetPosition, screenCoordinate: touchedPosition))
    }
    
    
    ///  画面座標をタイル座標に変換する
    ///
    ///  - parameter sheetPosition:   タイルシートの位置
    ///  - parameter touchedPosition: タッチされた座標
    ///
    ///  - returns: 最も近いタイルのタイル座標
    class func getTileCoordinateFromScreenCoordinate(
        sheetPosition: CGPoint,
        screenCoordinate: CGPoint
    ) -> TileCoordinate {
        return TileCoordinate(
            x: Int(floor((screenCoordinate.x - sheetPosition.x) / CGFloat(Tile.TILE_SIZE) + 1)),
            y: Int(floor((screenCoordinate.y - sheetPosition.y) / CGFloat(Tile.TILE_SIZE) + 1)))
    }

    
    ///  シート座標をタイル座標に変換する
    ///
    ///  - parameter sheetPosition: シート座標
    ///
    ///  - returns: タイル座標
    class func getTileCoordinateFromSheetCoordinate(sheetCoordinate: CGPoint) -> TileCoordinate {
        return TileCoordinate(x: Int(floor(sheetCoordinate.x / CGFloat(Tile.TILE_SIZE) + 1)),
                              y: Int(floor(sheetCoordinate.y / CGFloat(Tile.TILE_SIZE) + 1)))
    }
    
    
    class func getSheetCoordinateFromScreenCoordinate(
        sheetPosition: CGPoint,
        screenCoordinate: CGPoint
    ) -> CGPoint {
        return CGPointMake(screenCoordinate.x + sheetPosition.x, screenCoordinate.y + sheetPosition.y)
    }
    
    
    ///  タイル座標をシート座標に変換する
    ///  シート座標は，該当タイルの中心の値を返す
    ///
    ///  - parameter coordinate: タイル座標
    ///
    ///  - returns: シート座標
    class func getSheetCoordinateFromTileCoordinate(tileCoordinate: TileCoordinate) -> CGPoint {
        return CGPointMake(CGFloat(tileCoordinate.getX()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2,
                           CGFloat(tileCoordinate.getY()) * Tile.TILE_SIZE - Tile.TILE_SIZE / 2)
    }
}