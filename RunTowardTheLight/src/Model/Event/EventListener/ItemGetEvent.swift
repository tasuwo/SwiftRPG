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

class ShowItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType
    private(set) var executionType: ExecutionType

    init(params: JSON?, nextEventListener listener: EventListener) {
        self.triggerType = .Immediate
        self.executionType = .Onece
        self.invoke = { (sender: AnyObject!, args: JSON!) -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            let itemKey = params!["key"].string
            let itemName = params!["name"].string
            if itemKey == nil || itemName == nil {
                print("Invalid arguement for getting item")
                return
            }

            scene.eventDialog.hidden = false
            scene.eventDialog.text = "\(itemName!) を手に入れた"

            self.delegate?.invoke(self, listener: ItemGetDialogEventListener(params: params, nextEventListener: listener))
        }
    }
}

class ItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: (sender: AnyObject!, args: JSON!) -> ()!
    private(set) var triggerType: TriggerType = .Touch
    private(set) var executionType: ExecutionType = .Loop

    private var isDialogShown = false
    private var itemName = ""

    init(params: JSON?, nextEventListener listener: EventListener) {
        self.invoke = { sender, args -> () in }
        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene

            scene.eventDialog.hidden = true
            self.delegate?.invoke(self, listener: listener)
        }
        self.executionType = .Onece
    }
}