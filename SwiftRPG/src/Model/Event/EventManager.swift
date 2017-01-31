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
    internal var unavailabledCyclicEventIds: [UInt64] = []

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

    func trigger(_ type: TriggerType, sender: GameSceneProtocol!, args: JSON!) throws {
        if isBlockingTrigger { return }

        let dispacher = self.getDispacherOf(type)
        do {
            try dispacher.trigger(sender, args: args)
        } catch EventDispacherError.FiledToInvokeListener(let string) {
            throw EventManagerError.FailedToTrigger(string)
        }
    }

    // MARK: - Unavailable, Block/Unblock methods

    // Permanently block  event listeners which existed at the time of called this function
    // TODO: Block touch event during executing this function
    func unavailableAllListeners() {
        self.isBlockingTrigger = true

        // Make target listeners already added to unavailable
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
            if listener.triggerType == .immediate {
                self.unavailabledCyclicEventIds.append(listener.id)
                continue
            }
        }

        self.isBlockingTrigger = false
    }

    func blockBehavior() {
        self.isBlockingTrigger = true

        // Make target listeners already added to unavailable
        let listeners = self.cyclicEventDispacher.getAllListeners()
        for l in listeners {
            if l.isBehavior {
                self.unavailabledCyclicEventIds.append(l.id)
            }
        }

        // Prevent to invoke other listener for target listener
        self.isBlockingBehavior = true

        self.isBlockingTrigger = false
    }

    func unblockBehavior() {
        self.isBlockingBehavior = false
    }

    func blockWalking() {
        self.isBlockingTrigger = true

        // Make target listeners already added to unavailable
        let tListeners = self.touchEventDispacher.getAllListeners()
        for l in tListeners {
            if (l as? WalkEventListener) != nil {
                self.touchEventDispacher.remove(l)
            }
        }
        let cListeners = self.cyclicEventDispacher.getAllListeners()
        for l in cListeners {
            if (l as? WalkOneStepEventListener) != nil {
                self.unavailabledCyclicEventIds.append(l.id)
            }
        }

        // Prevent to invoke other listener for target listener
        self.isBlockingWalking = true

        self.isBlockingTrigger = false
    }

    func unblockWalking() {
        self.isBlockingWalking = false
    }

    // MARK: -
    
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
            if self.unavailabledCyclicEventIds.contains(id) {
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

    func invoke(_ listener: EventListener, invoker: EventListener) {
        let nextListenersDispacher = self.getDispacherOf(listener.triggerType)

        for id in self.unavailabledCyclicEventIds {
            if id == invoker.id && invoker.triggerType == .immediate {
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
