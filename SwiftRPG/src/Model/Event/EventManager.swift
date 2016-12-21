//
//  EventManager.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/02.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

protocol NotifiableFromDispacher {
    func invoke(_ invoker: EventListener, listener: EventListener)
}

class EventManager: NotifiableFromDispacher {
    fileprivate(set) var touchEventDispacher: EventDispatcher
    fileprivate(set) var actionButtonEventDispacher: EventDispatcher
    fileprivate(set) var objectEventDispacher: EventDispatcher
    fileprivate(set) var cyclicEventDispacher: EventDispatcher

    init() {
        self.touchEventDispacher = EventDispatcher()
        self.actionButtonEventDispacher = EventDispatcher()
        self.objectEventDispacher = EventDispatcher()
        self.cyclicEventDispacher = EventDispatcher()

        self.touchEventDispacher.delegate = self
        self.actionButtonEventDispacher.delegate = self
        self.objectEventDispacher.delegate = self
        self.cyclicEventDispacher.delegate = self
    }

    func add(_ listener: EventListener) {
        let dispacher = self.getDispacherOf(listener)
        dispacher.add(listener)
    }

    fileprivate func getDispacherOf(_ listener: EventListener) -> EventDispatcher {
        switch listener.triggerType {
        case .touch:
            return self.touchEventDispacher
        case .button:
            return self.actionButtonEventDispacher
        case .immediate:
            return self.cyclicEventDispacher
        }
    }

    // MARK: - NotifiableFromDispacher

    func invoke(_ invoker: EventListener, listener: EventListener) {
        let invokerDispacher = self.getDispacherOf(invoker)
        let nextListenersDispacher = self.getDispacherOf(listener)
        invokerDispacher.remove(invoker)
        // TODO: うまく排他制御する
        nextListenersDispacher.removeAll()
        nextListenersDispacher.add(listener)
    }
}
