//
//  EventListener.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/09/04.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import SpriteKit

enum EventListenerError: Error {
    case illegalArguementFormat(String)
    case illegalParamFormat([String])
    case invalidParam(String)
}

enum TriggerType {
    case touch
    case immediate
    case button
}

enum ExecutionType {
    case onece
    case loop
}

protocol GameSceneProtocol {
    var actionButton: UIButton! { get set }
    var menuButton: UIButton! { get set }
    var eventDialog: DialogLabel! { get set }
    var map: Map? { get set }
    var textBox: Dialog! { get set }

    func movePlayer(_ playerActions: [SKAction], destination: CGPoint, events: [EventListener], screenActions: [SKAction])
    func hideAllButtons()
    func showOnlyDefaultButtons()
}

typealias EventMethod = (_ sender: GameSceneProtocol?, _ args: JSON?) throws -> ()
protocol EventHandler: class {
    var invoke: EventMethod? { get set }
    var triggerType: TriggerType { get }
    var executionType: ExecutionType { get }
}

typealias ListenerChain = [(listener: EventListener.Type, params: JSON?)]
protocol EventListener: EventHandler {
    var id: UInt64! { get set }
    var delegate: NotifiableFromListener? { get set }
    init(params: JSON?, chainListeners: ListenerChain?) throws
}
