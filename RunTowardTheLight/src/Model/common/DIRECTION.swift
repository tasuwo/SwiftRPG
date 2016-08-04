//
//  DIRECTION.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

enum DIRECTION {
    case UP, DOWN, LEFT, RIGHT

    var toString : String! {
        switch self {
        case .UP:
            return "UP"
        case .DOWN:
            return "DOWN"
        case .LEFT:
            return "LEFT"
        case .RIGHT:
            return "RIGHT"
        }
    }

    var reverse: DIRECTION {
        switch self {
        case .UP:
            return .DOWN
        case .DOWN:
            return .UP
        case .LEFT:
            return .RIGHT
        case .RIGHT:
            return .LEFT
        }
    }

    static func fromString(direction: String) -> DIRECTION? {
        switch direction {
        case "UP":
            return DIRECTION.UP
        case "DOWN":
            return DIRECTION.DOWN
        case "RIGHT":
            return DIRECTION.RIGHT
        case "LEFT":
            return DIRECTION.LEFT
        default:
            return nil
        }
    }
}
