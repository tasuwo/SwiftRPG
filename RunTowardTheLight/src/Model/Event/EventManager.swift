//
//  EventManager.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/02.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

class EventManager {
    private(set) var touchEventDispacher = EventDispatcher()
    private(set) var actionButtonEventDispacher = EventDispatcher()
    private(set) var objectEventDispacher = EventDispatcher()
    private(set) var cyclicEventDispacher = EventDispatcher()

    func add(listener: EventListener) {
        switch (listener.triggerType) {
        case .Touch:
            self.touchEventDispacher.removeAll()
            self.touchEventDispacher.add(listener)
        case .Immediate:
            self.cyclicEventDispacher.removeAll()
            self.cyclicEventDispacher.add(listener)
        case .Button:
            self.actionButtonEventDispacher.removeAll()
            self.actionButtonEventDispacher.add(listener)
        }
    }
}