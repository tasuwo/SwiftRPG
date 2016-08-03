//
//  EventListener.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/09/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON



protocol EventHandler: class {
    var invoke: (sender: AnyObject!, args: JSON!) -> ()! { get set }
}

protocol EventListener: EventHandler {
    var id: UInt64! { get set }
    var delegate: NotifiableFromListener? { get set }
    var nextListener: EventListener? { get }
}
