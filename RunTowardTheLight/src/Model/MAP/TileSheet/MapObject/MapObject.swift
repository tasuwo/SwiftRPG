//
//  MapObject.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/15.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

protocol MapObject {
    var hasCollision: Bool { get }
    
    var events: [EventListener] { get }

    var parent: MapObject? { get }
    
    func setCollision()
    
    func setEvents(events: [EventListener])
}