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

    func add(_ listener: EventListener) -> Bool {
        let dispacher = self.getDispacherOf(listener)
        if dispacher.add(listener) == false {
            return false
        } else {
            return true
        }
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

    // TODO: remove, add が失敗した場合の処理の追加
    func invoke(_ invoker: EventListener, listener: EventListener) {
        let invokerDispacher = self.getDispacherOf(invoker)
        let nextListenersDispacher = self.getDispacherOf(listener)

        // 呼び出し元の EventListener 自身を Dispacher から削除する
        if invokerDispacher.remove(invoker) == false {}

        // TODO: うまく排他制御する
        nextListenersDispacher.removeAll()
        if nextListenersDispacher.add(listener) == false { return }
    }
}
