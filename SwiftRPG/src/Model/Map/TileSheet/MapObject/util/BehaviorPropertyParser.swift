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
    class func parse(from properties: String, parentId: MapObjectId) throws -> EventListener? {
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

        chain = chain + [(listener: ReloadBehaviorEventListener.self, params: JSON(["eventObjectId":parentId]) as JSON?)]

        var listener: EventListener? = nil
        let listenerType = chain.first?.listener
        let params = chain.first?.params
        do {
            listener = try listenerType?.init(
                params: params,
                chainListeners: ListenerChain(chain.dropFirst(1)))
        } catch EventListenerError.illegalArguementFormat(let string) {
            throw ListenerGeneratorError.failed("Illegal arguement for listener: " + string)
        } catch EventListenerError.illegalParamFormat(let array) {
            throw ListenerGeneratorError.failed("Illegal parameter for listener: " + array.joined(separator: ","))
        } catch EventListenerError.invalidParam(let string) {
            throw ListenerGeneratorError.failed("Invalid parameter for listener: " + string)
        } catch EventParserError.invalidProperty(let string) {
            throw ListenerGeneratorError.failed("Invalid property for listener: " + string)
        }

        return listener
    }
}
