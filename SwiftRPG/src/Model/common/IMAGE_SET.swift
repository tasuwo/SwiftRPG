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

    func get(direction: DIRECTION) -> [[String]] {
        switch direction {
        case .UP:
            return self.UP
        case .DOWN:
            return self.DOWN
        case .LEFT:
            return self.LEFT
        case .RIGHT:
            return self.RIGHT
        }
    }
}
