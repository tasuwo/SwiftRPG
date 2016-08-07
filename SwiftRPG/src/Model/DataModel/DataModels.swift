//
//  DataModels.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

class StoredItems: RealmSwift.Object {
    dynamic var key: String = ""
    dynamic var name: String = ""
    dynamic var text: String = ""
    dynamic var image_name: String = ""
    dynamic var num: Int = 0

    override static func primaryKey() -> String? {
        return "key"
    }
}
