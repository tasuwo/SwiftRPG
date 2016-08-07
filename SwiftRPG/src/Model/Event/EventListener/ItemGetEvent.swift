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

/// アイテムゲットのリスナー
/// - アイテムをDBに保存
/// - アイテムゲットのダイアログを表示
class ShowItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    private let params: JSON
    private let listeners: ListenerChain?
    private let itemKey: String
    private let itemName: String
    private let itemText: String
    private let itemImageName: String

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .Immediate
        self.executionType = .Onece

        if params == nil {
            throw EventListenerError.ParamIsNil
        }
        self.params = params!
        self.listeners = listeners

        let itemKey = params!["key"].string
        let itemName = params!["name"].string
        let itemText = params!["description"].string
        let itemImageName = params!["image_name"].string
        if itemKey == nil || itemName == nil || itemText == nil || itemImageName == nil {
            throw EventListenerError.IllegalParamFormat(EventListenerError.generateIllegalParamFormatErrorMessage(
                ["key": itemKey, "name": itemName, "description": itemText, "image_name": itemImageName],
                handler: ShowItemGetDialogEventListener.self)
            )
        }
        self.itemKey = itemKey!
        self.itemName = itemName!
        self.itemText = itemText!
        self.itemImageName = itemImageName!

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            scene.eventDialog.hidden = false

            let realm = try! Realm()
            try! realm.write {
                var item = realm.objects(StoredItems).filter("key == \"\(self.itemKey)\"").first
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

            scene.eventDialog.text = "\(self.itemName) を手に入れた．"

            self.delegate?.invoke(self, listener: CloseItemGetDialogEventListener(params: self.params, chainListeners: self.listeners))
        }
    }
}

/// アイテムゲット終了のリスナ
/// - アイテムゲットのダイアログを閉じる
class CloseItemGetDialogEventListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .Touch
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene

            scene.eventDialog.hidden = true

            if listeners?.count == 0 || listeners == nil { return }
            let nextListener = listeners?.first?.listener
            let nextChainListeners = Array(listeners!.dropFirst())
            let nextListenerInstance: EventListener
            do {
                nextListenerInstance = try nextListener!.init(params: listeners?.first?.params, chainListeners: nextChainListeners)
            } catch {
                throw error
            }
            self.delegate?.invoke(self, listener: nextListenerInstance)
        }
    }
}