//
//  ItemGetEvent.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import RealmSwift

class ItemGetEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var rollback: EventMethod?
    var isExecuting: Bool = false
    var eventObjectId: MapObjectId? = nil
    let triggerType: TriggerType
    let executionType: ExecutionType

    internal var listeners: ListenerChain?
    fileprivate let params: JSON
    fileprivate let itemKey: String
    fileprivate let itemName: String
    fileprivate let itemText: String
    fileprivate let itemImageName: String

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "key": ["type": "string"],
                "name": ["type": "string"],
                "description": ["type": "string"],
                "image_name": ["type": "string"],
            ],
            "required": ["key", "name", "description", "image_name"],
        ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        
        self.triggerType   = .immediate
        self.executionType = .onece
        self.params        = params!
        self.listeners     = listeners
        self.itemKey       = params!["key"].string!
        self.itemName      = params!["name"].string!
        self.itemText      = params!["description"].string!
        self.itemImageName = params!["image_name"].string!
        self.invoke        = { (sender: GameSceneProtocol?, args: JSON?) -> () in
            // Insert data to database
            let realm = try! Realm()
            try! realm.write {
                var item = realm.objects(StoredItems.self).filter("key == \"\(self.itemKey)\"").first
                if item != nil {
                    item!.num += 1
                } else {
                    item = StoredItems()
                    item!.key = self.itemKey
                    item!.name = self.itemName
                    item!.text = self.itemText
                    item!.image_name = self.itemImageName
                }
                realm.add(item!, update: true)
            }

            do {
                let nextEventListener = try InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
                nextEventListener.eventObjectId = self.eventObjectId
                self.delegate?.invoke(self, listener: nextEventListener)
            } catch {
                throw error
            }
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}
