//
//  TileCoordinate.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation

class TileCoordinate {
    private let x: Int!
    private let y: Int!
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    func getX() -> Int {
        return self.x
    }

    func getY() -> Int {
        return self.y
    }

    func isEqual(coordinate: TileCoordinate) -> Bool {
        return (x == coordinate.getX() &&
                y == coordinate.getY())
    }
}