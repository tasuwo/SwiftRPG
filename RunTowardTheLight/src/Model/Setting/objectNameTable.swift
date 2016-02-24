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
    
    static let PLAYER_IMAGE_UP = "plr_up.png"
    static let PLAYER_IMAGE_DOWN = "plr_down.png"
    static let PLAYER_IMAGE_RIGHT = "plr_right.png"
    static let PLAYER_IMAGE_LEFT = "plr_left.png"
    static let PLAYER_IMAGE_SET = IMAGE_SET(
        UP: PLAYER_IMAGE_UP,
        DOWN: PLAYER_IMAGE_DOWN,
        RIGHT: PLAYER_IMAGE_RIGHT,
        LEFT: PLAYER_IMAGE_LEFT
    )
}