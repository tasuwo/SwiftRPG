//
//  Event.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/12.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

// 登録されたリスナーにイベントを通知する
class EventDispatcher<EventArgType> {
    typealias SelfType = EventDispatcher<EventArgType>
    typealias ListenerType = EventListener<EventArgType>
    typealias IdType = EventListener<EventArgType>.IdType

    private var listeners = Dictionary<IdType, EventListener<EventArgType>>()
    private var uniqueId: IdType = 0
    // id発行に使う

    init() {}

    func add(listener: ListenerType) -> Bool {
        if listener.id != nil {
            return false
        }
        // id を付与
        let id = issueId()
        listeners[id] = listener
        listener.id = id
        return true;
    }

    // リスナー削除
    // ToDo: removeの為にlistener覚えておくのはもったいないのでIdにしたほうがいいかも
    func remove(listener: ListenerType) -> Bool {
        if listener.id == nil {
            return false
        }
        listeners.removeValueForKey(listener.id!)
        listener.id = nil
        return true;
    }

    // TODO: Listener 同士のつなぎをどうするかx
    func trigger(sender: AnyObject!, args: EventArgType!) {
        for listener in listeners.values {
            listener.invoke(sender: sender, args: args)
        }
    }

    // リスナーを識別するためのID発行
    private func issueId() -> IdType {
        repeat {
            uniqueId++
            if listeners[uniqueId] == nil {
                return uniqueId
            }
        } while (true) // ToDo
    }
}
