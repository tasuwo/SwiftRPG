//
//  DIRECTION.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

enum DIRECTION {
    case up, down, left, right

    var toString : String! {
        switch self {
        case .up:
            return "UP"
        case .down:
            return "DOWN"
        case .left:
            return "LEFT"
        case .right:
            return "RIGHT"
        }
    }

    var reverse: DIRECTION {
        switch self {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        }
    }

    static func fromString(_ direction: String) -> DIRECTION? {
        switch direction {
        case "UP":
            return DIRECTION.up
        case "DOWN":
            return DIRECTION.down
        case "RIGHT":
            return DIRECTION.right
        case "LEFT":
            return DIRECTION.left
        default:
            return nil
        }
    }
}
