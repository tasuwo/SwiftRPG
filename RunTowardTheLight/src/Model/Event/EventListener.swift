//
//  EventListener.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/09/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

enum TriggerType {
    case Touch
    case Immediate
    case Button
}

enum ExecutionType {
    case Onece
    case Loop
}

typealias EventMethod = (sender: AnyObject!, args: JSON!) -> ()
protocol EventHandler: class {
    var invoke: EventMethod! { get set }
    var triggerType: TriggerType { get }
    var executionType: ExecutionType { get }
}

typealias ListenerChain = [(listener: EventListener.Type, params: JSON?)]
protocol EventListener: EventHandler {
    var id: UInt64! { get set }
    var delegate: NotifiableFromListener? { get set }
    init(params: JSON?, chainListeners: ListenerChain?)
}
