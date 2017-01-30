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
    func invoke(_ listener: EventListener, invoker: EventListener)
}

enum EventManagerError: Error {
    case FailedToTrigger(String)
}

class EventManager: NotifiableFromDispacher {
    fileprivate var touchEventDispacher: EventDispatcher
    fileprivate var actionButtonEventDispacher: EventDispatcher
    fileprivate var cyclicEventDispacher: EventDispatcher

    fileprivate(set) var isBlockingBehavior: Bool = true
    fileprivate(set) var isBlockingWalking: Bool = true
    fileprivate(set) var isBlockingTrigger: Bool = false
    // WARNING: Event listener id is unique at each dispatcher, **not** at this manager.
    //          This value contains only cyclic event ids.
    // Touch and action event listeners are able to remove,
    // but cyclic events might be executed already at the time of removing.
    // So this value contains cyclic event listener's id and block them.
    fileprivate var blockedListenerIds: [UInt64] = []

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
                if listener_.eventObjectId == listener.eventObjectId
                && listener_.isBehavior == listener.isBehavior {
                    return false
                }
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
            if listener.eventObjectId == id
            && listener.isBehavior == false {
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

    // Permanently block  event listeners which existed at the time of called this function
    // TODO: Block touch event during executing this function
    func blockCurrentListeners() {
        self.isBlockingTrigger = true

        let listeners = self.getAllListeners()
        for listener in listeners {
            if listener.triggerType == .touch {
                if self.touchEventDispacher.remove(listener) == false {
                    print("Failed to remove listener")
                }
                continue
            }
            if listener.triggerType == .button {
                if self.actionButtonEventDispacher.remove(listener) == false {
                    print("Failed to remove listener")
                }
                continue
            }
            self.blockedListenerIds.append(listener.id)
        }

        self.isBlockingWalking = true
        self.isBlockingBehavior = true

        self.isBlockingTrigger = false
    }

    func blockBehavior() {
        self.isBlockingBehavior = true
    }

    func unblockBehavior() {
        self.isBlockingBehavior = false
    }

    func enableWalking() {
        var existsWalkEvent = false
        let listeners = self.getAllListeners()
        for listener in listeners {
            if listener as? WalkEventListener != nil {
                existsWalkEvent = true
            }
        }
        if existsWalkEvent == false {
            self.add(WalkEventListener.init(params: nil, chainListeners: nil))
        }

        self.isBlockingWalking = false
    }

    func disableWalking() {
        self.isBlockingWalking = true
    }

    func trigger(_ type: TriggerType, sender: GameSceneProtocol!, args: JSON!) throws {
        if isBlockingTrigger { return }

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
        var listenersDic: Dictionary<UInt64, EventListener> = [:]
        var listeners: [EventListener] = []
        listeners += self.touchEventDispacher.getAllListeners()
        listeners += self.actionButtonEventDispacher.getAllListeners()
        listeners += self.cyclicEventDispacher.getAllListeners()

        for listener in listeners {
            listenersDic[listener.id] = listener
        }

        for (id, _) in listenersDic {
            if self.blockedListenerIds.contains(id) {
                listenersDic.removeValue(forKey: id)
            }
        }

        listeners = []
        for listener in listenersDic.values {
            listeners.append(listener)
        }

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
    func invoke(_ listener: EventListener, invoker: EventListener) {
        let nextListenersDispacher = self.getDispacherOf(listener.triggerType)

        for (index, id) in self.blockedListenerIds.enumerated() {
            // blockListenrIds contains only cyclic event
            if id == invoker.id && invoker.triggerType == .immediate {
                self.blockedListenerIds.remove(at: index)
                return
            }
        }

        if isBlockingWalking && (listener as? WalkOneStepEventListener != nil) {
            return
        }

        if isBlockingBehavior && listener.isBehavior {
            return
        }

        if !nextListenersDispacher.add(listener) {
            print("Failed to add listener" )
        }
    }
}
