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
    func invoke(_ invoker: EventListener, listener: EventListener)
}

class EventDispatcher : NotifiableFromListener {
    typealias ListenerType = EventListener
    typealias IdType = UInt64

    fileprivate var listeners = Dictionary<IdType, ListenerType>()
    fileprivate var uniqueId: UInt64 = 0

    var delegate: NotifiableFromDispacher?

    init() {}

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

        listeners.removeValue(forKey: listener.id!)
        listener.id = nil
        return true
    }

    @discardableResult
    func removeByEventObjectId(_ listener: ListenerType, sender: GameSceneProtocol? = nil) -> Bool {
        if listener.eventObjectId == nil { return false }
        var targetListener: EventListener? = nil

        for listener_ in self.listeners.values {
            if listener_.eventObjectId == listener.eventObjectId {
                targetListener = listener_
                break
            }
        }

        if let targetListener_ = targetListener {
            return self.remove(targetListener_, sender: sender)
        }

        return false
    }
    
    func removeAll() {
        listeners.removeAll()
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
                    if listener.executionType == .onece {
                        self.remove(listener, sender: sender)
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

    func invoke(_ invoker: EventListener, listener nextListener: EventListener) {
        self.delegate?.invoke(invoker, listener: nextListener)
    }
}


