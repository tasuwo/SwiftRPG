//
//  MapObject.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/02/15.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

enum MapObjectError: Error {
    case failedToGenerate(String)
}

typealias MapObjectId = Int
protocol MapObject {
    // TODO: MapObjectId will confused because it could contain different class's id which is inherit MapObject
    /// Map object could have parent-child relationship.
    /// There are some usage for these...
    ///   - Sometimes you want to tying events to the map object.
    ///     This could realize by adding map objects having event to target map object as children, 
    ///     and manage the child map object's as "event object"
    ///   - MapObject should have only one tile coordinate.
    ///     But sometimes you want to add large map object (i.e. the map object acrossing some tiles
    ///     In above situation, parent-child relationship of map object could use for grouping for map objects.

    var parent: MapObjectId? { get set }

    var children: [MapObjectId] { get set }

    /// For collision detection

    var hasCollision: Bool { get }

    func setCollision()

    /// Each map object has id.
    /// This id should be used for identification of objects 
    /// which inherit same *class*, not same *protocol*.

    var id: MapObjectId { get }

    static var nextId: MapObjectId { get }

    static func generateId() -> MapObjectId
}

