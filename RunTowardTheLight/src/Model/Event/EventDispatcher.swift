//
//  Event.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/12.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

/// リスナーにイベントを通知する
public class EventDispatcher<EventArgType> {
    typealias SelfType = EventDispatcher<EventArgType>
    typealias ListenerType = EventListener<EventArgType>
    typealias IdType = EventListener<EventArgType>.IdType

    /// リスナー群
    private var listeners = Dictionary<IdType, EventListener<EventArgType>>()
    
    /// ユニークなID．ID発行に使う
    private var uniqueId: IdType = 0

    init() {}

    ///  リスナーを登録する
    ///
    ///  - parameter listener: 追加するイベントリスナー．IDが未割り当てだと失敗する
    ///
    ///  - returns: 追加に成功したら true
    func add(listener: ListenerType) -> Bool {
        if listener.id != nil { return false }
        let id = issueId()
        listeners[id] = listener
        listener.id = id
        return true
    }

    ///  リスナーを削除する
    ///
    ///  - parameter listener: 削除するリスナー
    ///
    ///  - returns: 成功ならtrue, 失敗なら false
    func remove(listener: ListenerType) -> Bool {
        if listener.id == nil { return false }
        listeners.removeValueForKey(listener.id!)
        listener.id = nil
        return true
    }
    
    func removeAll() {
        listeners.removeAll()
    }

    ///  リスナーにイベントを通知する
    ///  TODO : Listener 同士のつなぎをどうするか
    ///
    ///  - parameter sender: イベントの呼び出し元
    ///  - parameter args:   コールバック関数への引数
    func trigger(sender: AnyObject!, args: EventArgType!) {
        for listener in listeners.values {
            listener.invoke(sender: sender, args: args)
        }
    }
    
    ///  リスナーを保持しているか
    ///
    ///  - returns: 保持していれば true, 保持していなければ false
    func hasListener() -> Bool {
        return self.listeners.count > 0
    }

    ///  リスナーを識別するためのIDを発行する
    ///
    ///  - returns: ユニークなID
    private func issueId() -> IdType {
        repeat {
            uniqueId += 1
            if listeners[uniqueId] == nil {
                return uniqueId
            }
        } while (true) // ToDo
    }
}
