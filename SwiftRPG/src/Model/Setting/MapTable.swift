//
//  MapTable.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/29.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation

struct MapTable {
    static let fromJsonFileName: Dictionary<String, GameScene.Type> = [
        "sample_map02.json": myGameScene.self,
        "sample_map01.json": nextGameScene.self
    ]
}
