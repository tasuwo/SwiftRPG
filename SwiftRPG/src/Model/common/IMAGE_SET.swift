//
//  IMAGE_SET.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

struct IMAGE_SET {
    let UP: [[String]]
    let DOWN: [[String]]
    let RIGHT: [[String]]
    let LEFT: [[String]]

    func get(_ direction: DIRECTION) -> [[String]] {
        switch direction {
        case .up:
            return self.UP
        case .down:
            return self.DOWN
        case .left:
            return self.LEFT
        case .right:
            return self.RIGHT
        }
    }
}
