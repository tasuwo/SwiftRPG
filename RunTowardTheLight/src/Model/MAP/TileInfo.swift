//
//  TileInfo.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/14.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit

typealias TileID = Int
typealias TileSetID = Int
typealias TileProperty = Dictionary<String, String>

class TileInfo {
    /// タイルID
    let tileID: Int
    /// あたり判定の有無
    var hasCollision: Bool
    /// 設置されているオブジェクトのオブジェクトID
    var objectID: Int
    
    var properties: Dictionary<String, String> = [:]
    
    init(tileID: Int, hasCollision: Bool, objectID: Int) {
        self.tileID = tileID
        self.hasCollision = hasCollision
        self.objectID = objectID
    }
    
    func setProperty(key: String, value: String) {
        self.properties[key] = value
    }
}
