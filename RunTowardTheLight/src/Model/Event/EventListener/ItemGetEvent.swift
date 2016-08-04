//
//  ItemGetEvent.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit
import RealmSwift

class ShowItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: ((sender: AnyObject!, args: JSON!) -> ())!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, nextEventListener listener: EventListener.Type?) {
        self.triggerType = .Immediate
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            let itemKey = params!["key"].string
            let itemName = params!["name"].string
            let itemText = params!["description"].string
            let itemImageName = params!["image_name"].string
            if itemKey == nil || itemName == nil || itemText == nil || itemImageName == nil {
                print("Invalid arguement for getting item")
                return
            }

            scene.eventDialog.hidden = false

            let realm = try! Realm()
            try! realm.write {
                var item = realm.objects(StoredItems).filter("key == \"\(itemKey!)\"").first
                if item != nil {
                    item!.num += 1
                } else {
                    item = StoredItems()
                    item!.key = itemKey!
                    item!.name = itemName!
                    item!.text = itemText!
                    item!.image_name = itemImageName!
                }
                realm.add(item!, update: true)
            }

            scene.eventDialog.text = "\(itemName!) を手に入れた．"

            self.delegate?.invoke(self, listener: ItemGetDialogEventListener(params: params, nextEventListener: listener))
        }
    }
}

class ItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: ((sender: AnyObject!, args: JSON!) -> ())!
    let triggerType: TriggerType
    let executionType: ExecutionType

    private var isDialogShown = false
    private var itemName = ""

    required init(params: JSON?, nextEventListener listener: EventListener.Type?) {
        self.triggerType = .Touch
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene

            scene.eventDialog.hidden = true
            self.delegate?.invoke(self, listener: listener!.init(params: params, nextEventListener: nil))
        }
    }
}