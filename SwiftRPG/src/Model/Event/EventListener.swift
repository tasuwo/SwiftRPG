//
//  EventListener.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/09/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

enum EventListenerError: ErrorType {
    case IllegalArguementFormat(String)
    case IllegalParamFormat(String)
    case InvalidParam(String)
    case ParamIsNil

    static func generateIllegalParamFormatErrorMessage(params: [String:AnyObject?], handler: EventListener.Type) -> String {
        var message = "Some params are missing at \(handler)."
        message += " Check "
        for param in params {
            let key = param.0
            let value = param.1
            message += "`\(key)`(=\(value)), "
        }
        return message
    }
}

enum TriggerType {
    case Touch
    case Immediate
    case Button
}

enum ExecutionType {
    case Onece
    case Loop
}

typealias EventMethod = (sender: AnyObject!, args: JSON!) throws -> ()
protocol EventHandler: class {
    var invoke: EventMethod! { get set }
    var triggerType: TriggerType { get }
    var executionType: ExecutionType { get }
}

typealias ListenerChain = [(listener: EventListener.Type, params: JSON?)]
protocol EventListener: EventHandler {
    var id: UInt64! { get set }
    var delegate: NotifiableFromListener? { get set }
    init(params: JSON?, chainListeners: ListenerChain?) throws
}
