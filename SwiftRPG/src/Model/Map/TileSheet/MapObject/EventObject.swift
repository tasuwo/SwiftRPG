//
//  EventObject.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/26.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

open class EventObject: MapObject {
    fileprivate(set) var eventListener: EventListener
    fileprivate(set) var relativeCoordinateFromParent: TileCoordinate
    fileprivate(set) var relatedEventListenerId: Int?

    // MARK: - MapObject

    fileprivate(set) var id: MapObjectId
    fileprivate(set) var hasCollision: Bool
    fileprivate var parent_: MapObjectId?
    var parent: MapObjectId? {
        get {
            return self.parent_
        }
        set {
            self.parent_ = newValue
        }
    }
    fileprivate var children_: [MapObjectId] = []
    var children: [MapObjectId] {
        get {
            return self.children_
        }
        set {
            self.children_ = newValue
        }
    }
    func setCollision() {
        self.hasCollision = true
    }
    static var nextId = 0
    static func generateId() -> MapObjectId {
        nextId += 1
        return nextId
    }

    // MARK: -

    init(parentId: MapObjectId, relativeCoordinate: TileCoordinate, event: EventListener) {
        self.id = EventObject.generateId()
        self.parent_ = parentId
        self.relativeCoordinateFromParent = relativeCoordinate
        self.eventListener = event
        self.hasCollision = false
    }

    func registerListenerId(listenerId: Int) {
        self.relatedEventListenerId = listenerId
    }

    func removeListenerId() {
        self.relatedEventListenerId = nil
    }
}

