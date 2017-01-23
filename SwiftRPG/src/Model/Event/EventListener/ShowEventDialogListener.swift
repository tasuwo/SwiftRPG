//
//  ActivateEventDialogListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/23.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class ShowEventDialogListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listeners: ListenerChain?
    var params: JSON?
    let triggerType: TriggerType
    let executionType: ExecutionType

    ///  コンストラクタ
    ///
    ///  - parameter params:    JSON形式の引数．
    ///  - text : action button に表示するテキスト
    ///  - parameter listeners: 次に実行する event listener
    ///
    ///  - returns: なし
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {

        let schema = Schema([
            "type": "object",
            "properties": [
                "text": ["type": "string"],
            ],
            "required": ["text"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.params = params
        self.listeners = listeners
        self.triggerType = .immediate
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.eventDialog.text = params!["text"].string!
            sender!.eventDialog.isHidden = false

            let nextEventListener = HideEventDialogListener(params: self.params, chainListeners: self.listeners)
            self.delegate?.invoke(self, listener: nextEventListener)
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

class HideEventDialogListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    var listensers: ListenerChain?
    var params: JSON?
    let triggerType: TriggerType
    let executionType: ExecutionType
    internal var listeners: ListenerChain?

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .touch
        self.executionType = .onece
        self.listeners = listeners
        self.params = params
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.eventDialog.isHidden = true

            let nextEventListener = InvokeNextEventListener(params: self.params, chainListeners: self.listeners)
            self.delegate?.invoke(self, listener: nextEventListener)
        }
    }

    internal func chain(listeners: ListenerChain) {
        self.listeners = listeners
    }
}

