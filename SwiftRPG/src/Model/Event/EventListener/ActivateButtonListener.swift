//
//  ActivateButtonListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/06.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
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
    ///    - text : action button に表示するテキスト
    ///  - parameter listeners: 次に実行する event listener
    ///
    ///  - returns: なし
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        self.triggerType = .immediate
        self.executionType = .onece

        if params == nil {
            throw EventListenerError.paramIsNil
        }

        let text = params!["text"].string
        if text == nil {
            throw EventListenerError.illegalParamFormat(EventListenerError.generateIllegalParamFormatErrorMessage(
                ["text": text as Optional<AnyObject>],
                handler: ActivateButtonListener.self)
            )
        }
        self.text = text!

        self.invoke = {
            (sender: AnyObject?, args: JSON?) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            scene.actionButton.titleLabel?.text = self.text
            scene.actionButton.isHidden = false

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

