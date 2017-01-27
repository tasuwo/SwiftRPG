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
    func remove(_ listener: ListenerType) -> Bool {
        if listener.id == nil { return false }
        listeners.removeValue(forKey: listener.id!)
        listener.id = nil
        return true
    }

    @discardableResult
    func removeByEventObjectId(_ listener: ListenerType) -> Bool {
        if listener.eventObjectId == nil { return false }
        var key: IdType? = nil
        for (key_, listener_) in self.listeners {
            if listener_.eventObjectId == listener.eventObjectId {
                key = key_
            }
        }

        if let k = key {
            listeners.removeValue(forKey: k)
            return true
        } else {
            return false
        }
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
            do {
                if !listener.isExecuting {
                    try listener.invoke!(sender, args)
                }

                if listener.executionType == .onece {
                    self.remove(listener)
                }
            } catch EventListenerError.illegalArguementFormat(let string) {
                self.remove(listener)
                throw EventDispacherError.FiledToInvokeListener("Illegal arguement format:" + string)
            } catch EventListenerError.illegalParamFormat(let array) {
                self.remove(listener)
                throw EventDispacherError.FiledToInvokeListener("Failed to invoke listener:" + array.description)
            } catch EventListenerError.invalidParam(let string) {
                self.remove(listener)
                throw EventDispacherError.FiledToInvokeListener("Invalid parameter:" + string)
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


