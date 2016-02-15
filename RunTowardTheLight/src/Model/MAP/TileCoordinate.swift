//
//  TileCoordinate.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation

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
}