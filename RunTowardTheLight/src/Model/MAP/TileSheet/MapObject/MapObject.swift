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
    
    /// イベント
    var event: (EventDispatcher<Any>, [String])? { get }
    
    func canPass() -> Bool
    
    func setCollision()
    
    func setEvent(event: EventDispatcher<Any>, args: [String])
    
    func getEvent() -> (EventDispatcher<Any>, [String])?
}