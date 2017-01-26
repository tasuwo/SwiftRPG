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
import PromiseKit

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

    func movePlayer(_ playerActions: [SKAction], tileDeparture: TileCoordinate, tileDestination: TileCoordinate, screenActions: [SKAction]) -> Promise<Void> 
    func moveObject(_ name: String, actions: [SKAction], tileDeparture: TileCoordinate, tileDestination: TileCoordinate) -> Promise<Void>
    func hideAllButtons() -> Promise<Void>
    func showDefaultButtons() -> Promise<Void>
    func showEventDialog() -> Promise<Void>
    func registerEvent(listeners: [EventListener])
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
    var listeners: ListenerChain? { get }
    var isExecuting: Bool { get }
    var eventObjectId: MapObjectId? { get set }
    func chain(listeners: ListenerChain)
    init(params: JSON?, chainListeners: ListenerChain?) throws
}
