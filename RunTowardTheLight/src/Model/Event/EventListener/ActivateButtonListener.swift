//
//  ActivateButtonListener.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/06.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit

class ActivateButtonListener: EventListener {
    var id: UInt64!
    var delegate: NotifiableFromListener?
    var invoke: EventMethod!
    let triggerType: TriggerType
    let executionType: ExecutionType

    required init(params: JSON?, chainListeners listeners: ListenerChain?) {
        self.triggerType = .Immediate
        self.executionType = .Onece

        self.invoke = {
            (sender: AnyObject!, args: JSON!) -> () in
            let controller = sender as! GameViewController
            let skView     = controller.view as! SKView
            let scene: GameScene = skView.scene as! GameScene

            let text = params!["text"].string
            if text == nil {
                throw EventListenerError.IllegalParamFormat
            }

            scene.actionButton.titleLabel?.text = text!
            scene.actionButton.hidden = false

            if listeners == nil || listeners?.count == 0 { return }
            let nextListener = listeners!.first!.listener
            let nextParams = listeners!.first!.params
            let nextChainListeners = listeners?.count == 1 ? nil : Array(listeners!.dropFirst())
            self.delegate!.invoke(self, listener: nextListener.init(params: nextParams, chainListeners: nextChainListeners))
        }
    }
}

