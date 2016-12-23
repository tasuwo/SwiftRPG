//
//  ActivateButtonListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/06.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit

/// アクションボタン表示のリスナー
class ActivateButtonListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod?
    let triggerType: TriggerType
    let executionType: ExecutionType

    fileprivate let text: String

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

        self.text = params!["text"].string!
        self.triggerType = .immediate
        self.executionType = .onece
        self.invoke = {
            (sender: GameSceneProtocol?, args: JSON?) -> () in
            sender!.actionButton.titleLabel?.text = self.text
            sender!.actionButton.isHidden = false

            if listeners == nil || listeners?.count == 0 { return }
            let nextListener = listeners!.first!.listener
            let nextListenerChain: ListenerChain? = listeners?.count == 1 ? nil : Array(listeners!.dropFirst())
            let nextListenerInstance: EventListener
            do {
                nextListenerInstance = try nextListener.init(params: listeners?.first?.params, chainListeners: nextListenerChain)
            }
            self.delegate!.invoke(self, listener: nextListenerInstance)
        }
    }
}

