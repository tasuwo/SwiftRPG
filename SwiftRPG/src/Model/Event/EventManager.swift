//
//  EventManager.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/02.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol NotifiableFromDispacher {
    func invoke(_ invoker: EventListener, listener: EventListener)
}

enum EventManagerError: Error {
    case FailedToTrigger(String)
}

class EventManager: NotifiableFromDispacher {
    fileprivate var touchEventDispacher: EventDispatcher
    fileprivate var actionButtonEventDispacher: EventDispatcher
    fileprivate var cyclicEventDispacher: EventDispatcher

    init() {
        self.touchEventDispacher = EventDispatcher()
        self.actionButtonEventDispacher = EventDispatcher()
        self.cyclicEventDispacher = EventDispatcher()

        self.touchEventDispacher.delegate = self
        self.actionButtonEventDispacher.delegate = self
        self.cyclicEventDispacher.delegate = self
    }

    @discardableResult
    func add(_ listener: EventListener) -> Bool {
        let listeners = self.getAllListeners()
        if listener.eventObjectId != nil {
            for listener_ in listeners {
                // If there are listener which is generated from same event object, should be ignored.
                if listener_.eventObjectId == listener.eventObjectId { return false }
            }
        }
        let dispacher = self.getDispacherOf(listener.triggerType)
        if dispacher.add(listener) == false {
            return false
        } else {
            return true
        }
    }

    @discardableResult
    func remove(_ id: MapObjectId, sender: GameSceneProtocol? = nil) -> Bool {
        let listeners = self.getAllListeners()
        var targetListener: EventListener? = nil
        var targetDispacher: EventDispatcher? = nil

        for listener in listeners {
            if listener.eventObjectId == id {
                targetDispacher = self.getDispacherOf(listener.triggerType)
                targetListener = listener
                break
            }
        }

        if let l = targetListener,
           let d = targetDispacher {
            return d.remove(l, sender: sender)
        }

        return false
    }

    func trigger(_ type: TriggerType, sender: GameSceneProtocol!, args: JSON!) throws {
        let dispacher = self.getDispacherOf(type)
        do {
            try dispacher.trigger(sender, args: args)
        } catch EventDispacherError.FiledToInvokeListener(let string) {
            throw EventManagerError.FailedToTrigger(string)
        }
    }

    func existsListeners(_ type: TriggerType) -> Bool {
        let dispathcer = self.getDispacherOf(type)
        let listeners = dispathcer.getAllListeners()
        return !listeners.isEmpty
    }

    func shouldActivateButton() -> Bool {
        let listeners = self.getDispacherOf(.immediate).getAllListeners()
        for listener in listeners {
            if let _ = listener as? ActivateButtonListener {
                return true
            }
        }
        return false
    }

    // MARK: - Private methods

    fileprivate func getAllListeners() -> [EventListener] {
        var listeners: [EventListener] = []
        listeners += self.touchEventDispacher.getAllListeners()
        listeners += self.actionButtonEventDispacher.getAllListeners()
        listeners += self.cyclicEventDispacher.getAllListeners()
        return listeners
    }

    fileprivate func getDispacherOf(_ type: TriggerType) -> EventDispatcher {
        switch type {
        case .touch:
            return self.touchEventDispacher
        case .button:
            return self.actionButtonEventDispacher
        case .immediate:
            return self.cyclicEventDispacher
        }
    }

    // MARK: - NotifiableFromDispacher

    // TODO: remove, add が失敗した場合の処理の追加
    func invoke(_ invoker: EventListener, listener: EventListener) {
        let invokerDispacher = self.getDispacherOf(invoker.triggerType)
        let nextListenersDispacher = self.getDispacherOf(listener.triggerType)

        // Cannot execute following code:
        // In Listener chain, listeners which passed to here are defined as clojure in each event listeners.
        // The remove function of event dispatcher uses listener id which is specified at the time of adding listener to dispathcer.
        // But the clojure could only know about variables at the time of it is defined, so cannot access listener id from clojure.
        //   if invokerDispacher.remove(invoker) == false {}
        // Instead of listener id, we use event object id
        // Commonly, one event object has only one event listener chain, and it is defined at the time of 
        invokerDispacher.removeByEventObjectId(invoker)

        // TODO: うまく排他制御する
        // nextListenersDispacher.removeAll()
        if nextListenersDispacher.add(listener) == false { return }
    }
}
