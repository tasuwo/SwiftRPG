//
//  MapObject.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/15.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation


protocol MapObject {
    /// 当たり判定
    var hasCollision: Bool { get }
    
    var events: [EventListener] { get }

    var parent: MapObject? { get }
    
    func canPass() -> Bool
    
    func setCollision()
    
    func setEvents(events: [EventListener])
    
    func getEvents() -> [EventListener]?
}