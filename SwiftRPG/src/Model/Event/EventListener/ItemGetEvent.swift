//
//  ItemGetEvent.swift
//  SwiftRPG
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
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let params: JSON
    fileprivate let listeners: ListenerChain?
    fileprivate let itemKey: String
    fileprivate let itemName: String
    fileprivate let itemText: String
    fileprivate let itemImageName: String

    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .immediate
        self.executionType = .onece

        if params == nil {
            throw EventListenerError.paramIsNil
        }
        self.params = params!
        self.listeners = listeners

        let itemKey = params!["key"].string
        let itemName = params!["name"].string
        let itemText = params!["description"].string
        let itemImageName = params!["image_name"].string
        if itemKey == nil || itemName == nil || itemText == nil || itemImageName == nil {
            throw EventListenerError.illegalParamFormat(EventListenerError.generateIllegalParamFormatErrorMessage(
                ["key": itemKey as Optional<AnyObject>, "name": itemName as Optional<AnyObject>, "description": itemText as Optional<AnyObject>, "image_name": itemImageName as Optional<AnyObject>],
                handler: ShowItemGetDialogEventListener.self)
            )
        }
        self.itemKey = itemKey!
        self.itemName = itemName!
        self.itemText = itemText!
        self.itemImageName = itemImageName!

        self.invoke = {
            (sender: AnyObject?, args: JSON?) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            scene.eventDialog.isHidden = false

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
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .touch
        self.executionType = .onece

        self.invoke = {
            (sender: AnyObject?, args: JSON?) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene      = skView.scene as! GameScene

            scene.eventDialog.isHidden = true

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
