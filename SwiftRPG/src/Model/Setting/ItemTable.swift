//
//  ItemTable.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

struct Item {
    var key: String
    var name: String
    var description: String
    var image_name: String
}

struct ItemTable {
    static func get(key: String) -> Item? {
        for item in ItemTable.items {
            if item.key == key {
                return item
            }
        }
        return nil
    }

    static let items: [Item] = [
        Item(key: "test", name: "test object", description: "テスト用アイテムです", image_name: "kanamono_tile.png")
    ]
}