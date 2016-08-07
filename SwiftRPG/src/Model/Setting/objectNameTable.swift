//
//  objectNameTable.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/23.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

struct objectNameTable {
    static let PLAYER_NAME = "tasuwo"
    
    static let PLAYER_IMAGE_UP    = "plr_up.png"
    static let PLAYER_IMAGE_DOWN  = "plr_down.png"
    static let PLAYER_IMAGE_RIGHT = "plr_right.png"
    static let PLAYER_IMAGE_LEFT  = "plr_left.png"
    static let PLAYER_IMAGE_SET   = IMAGE_SET(
        UP:
        [
            ["plr_up_01.png", "plr_up.png"],
            ["plr_up_02.png", "plr_up.png"]
        ],
        DOWN:
        [
            ["plr_down_01.png", "plr_down.png"],
            ["plr_down_02.png", "plr_down.png"]
        ],
        RIGHT:
        [
            ["plr_right_01.png", "plr_right.png"],
            ["plr_right_02.png", "plr_right.png"]
        ],
        LEFT:
        [
            ["plr_left_01.png", "plr_left.png"],
            ["plr_left_02.png", "plr_left.png"]
        ]
    )
}