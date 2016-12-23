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

        let schema = Schema([
            "type": "object",
            "properties": [
                "key": ["type": "string"],
                "name": ["type": "string"],
                "description": ["type": "string"],
                "image_name": ["type": "string"],
            ],
            "required": ["talker", "talk_body", "talk_side"],
        ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }
        
        self.triggerType = .immediate
        self.executionType = .onece
        self.params = params!
        self.listeners = listeners
        self.itemKey = params!["key"].string!
        self.itemName = params!["name"].string!
        self.itemText = params!["description"].string!
        self.itemImageName = params!["image_name"].string!
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            // アイテムをデータベースに登録
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

            // ダイアログ更新
            sender!.eventDialog.isHidden = false
            sender!.eventDialog.text = "\(self.itemName) を手に入れた．"

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
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.eventDialog.isHidden = true

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
