//
//  EventManager.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/02.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

protocol NotifiableFromDispacher {
    func invoke(invoker: EventListener, listener: EventListener)
}

class EventManager: NotifiableFromDispacher {
    private(set) var touchEventDispacher: EventDispatcher
    private(set) var actionButtonEventDispacher: EventDispatcher
    private(set) var objectEventDispacher: EventDispatcher
    private(set) var cyclicEventDispacher: EventDispatcher

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

    func add(listener: EventListener) {
        let dispacher = self.getDispacherOf(listener)
        dispacher.add(listener)
    }

    private func getDispacherOf(listener: EventListener) -> EventDispatcher {
        switch listener.triggerType {
        case .Touch:
            return self.touchEventDispacher
        case .Button:
            return self.actionButtonEventDispacher
        case .Immediate:
            return self.cyclicEventDispacher
        }
    }

    // MARK: - NotifiableFromDispacher

    func invoke(invoker: EventListener, listener: EventListener) {
        let invokerDispacher = self.getDispacherOf(invoker)
        let nextListenersDispacher = self.getDispacherOf(listener)
        invokerDispacher.remove(invoker)
        // TODO: うまく排他制御する
        nextListenersDispacher.removeAll()
        nextListenersDispacher.add(listener)
    }
}