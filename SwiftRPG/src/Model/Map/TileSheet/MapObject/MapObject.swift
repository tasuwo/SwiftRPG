//
//  MapObject.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/02/15.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

enum MapObjectError: ErrorType {
    case FailedToGenerate(String)
}

protocol MapObject {
    var hasCollision: Bool { get }

    var events: [EventListener] { get set }

    var parent: MapObject? { get set }

    func setCollision()
}