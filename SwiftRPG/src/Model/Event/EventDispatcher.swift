//
//  Event.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2015/08/12.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit
import PromiseKit

enum EventDispacherError: Error {
    case FiledToInvokeListener(String)
}

protocol NotifiableFromListener {
    func invoke(_ listener: EventListener, invoker: EventListener)
}

class EventDispatcher : NotifiableFromListener {
    typealias ListenerType = EventListener
    typealias IdType = UInt64

    fileprivate var listeners = Dictionary<IdType, ListenerType>()
    fileprivate var uniqueId: UInt64 = 0

    let triggerType: TriggerType

    var delegate: NotifiableFromDispacher?

    init(_ type: TriggerType) {
        self.triggerType = type
    }

    @discardableResult
    func add(_ listener: ListenerType) -> Bool {
        if listener.id != nil { return false }
        let id = issueId()
        listener.delegate = self
        listeners[id] = listener
        listener.id = id
        return true
    }

    @discardableResult
    func remove(_ listener: ListenerType, sender: GameSceneProtocol? = nil) -> Bool {
        if listener.id == nil { return false }

        do {
            try listener.rollback?(sender, nil).catch { error in
                // TODO
            }
        } catch {
            // TODO
        }

        let id = listener.id!
        listeners.removeValue(forKey: id)
        listener.id = nil
        self.delegate?.removed(id, sender: self)

        return true
    }

    func getAllListeners() -> [EventListener] {
        var listeners: [EventListener] = []
        for listener in self.listeners.values {
            listeners.append(listener)
        }
        return listeners
    }

    // Invoke all event listenrs in this dispacher.
    // If exception has thrown during executing, remove the listener which thrown exception.
    func trigger(_ sender: GameSceneProtocol!, args: JSON!) throws {
        for listener in listeners.values {
            if !listener.isExecuting {
                try listener.invoke!(sender, args).then { _ -> Void in
                    // TODO:
                    // Should use remove() function
                    // But the function execute rollback()
                    // Need to prepare different remove function which is not executing rollback()
                    if let id_ = listener.id {
                        self.listeners.removeValue(forKey: id_)
                        listener.id = nil
                        self.delegate?.removed(id_, sender: self)
                    } else {
                        // If the listener was removed before removing in this block, here is executed
                        print("Failed to listener at the time of end of trigger")
                    }
                }.catch { error in
                    // TODO:
                }
            }
        }
    }

    func hasListener() -> Bool {
        return self.listeners.count > 0
    }

    fileprivate func issueId() -> IdType {
        repeat {
            uniqueId += 1
            if listeners[uniqueId] == nil {
                return uniqueId
            }
        } while (true) // ToDo
    }

    // MARK: NotifilableFromListener

    func invoke(_ nextListener: EventListener, invoker: EventListener) {
        self.delegate?.invoke(nextListener, invoker: invoker)
    }
}


