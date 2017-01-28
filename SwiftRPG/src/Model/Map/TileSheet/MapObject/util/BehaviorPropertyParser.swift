//
//  BehaviorPropertyParser.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/25.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SpriteKit
import SwiftyJSON

class BehaviorPropertyParser {
    class func parse(from properties: String, parentId: MapObjectId) throws -> ListenerChain? {
        var chain: ListenerChain = []
        let lines = properties.components(separatedBy: "\n")
        for line in lines {
            let params = line.components(separatedBy: ",")
            let type = params[0]
            let args = Array(params.dropFirst(1))
            do {
                chain += try ListenerContainer.getBy(type, directionToParent: nil, params: args)
            } catch {
                // TODO
            }
        }

        // For looping animation
        chain = chain + [
            (listener: ReloadBehaviorEventListener.self, params: JSON(["eventObjectId":parentId]) as JSON?)
        ]

        return chain
    }
}
