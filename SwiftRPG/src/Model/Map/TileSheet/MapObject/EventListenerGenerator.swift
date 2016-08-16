//
//  EventListenerGenerator.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

enum EventGeneratorError: ErrorType {
    case EventIdNotFound
    case InvalidParams(String)
}

class EventListenerGenerator {
    class func getListenerByID(id: String, directionToParent: DIRECTION?, params: [String]) throws -> EventListener {
        switch id {
        case "talk":
            let parser = TalkBodyParser(talkFileName: params[0])
            if parser == nil {
                throw EventGeneratorError.InvalidParams("Specified talk file (\(params[0])) is not found. Check your params (\(params.description) format)")
            }
            var paramsJson = parser?.parse()

            // direction を追加
            var array = paramsJson!.arrayObject as? [[String:String]]
            let directionString = directionToParent == nil ? "" : directionToParent!.toString
            array!.append(["direction":directionString])
            paramsJson = JSON(array!)

            do {
                return try ActivateButtonListener(params: JSON(["text":"はなす"]), chainListeners: [
                    (listener: StartTalkEventListener.self, params: paramsJson),
                    (listener: WalkEventListener.self, params: nil)
                ])
            } catch {
                throw error
            }
        case "item":
            let item = ItemTable.get(params[0])
            if item == nil {
                throw EventGeneratorError.InvalidParams("Specified item key (\(params[0])) in params(\(params.description)) is not found. Check ItemTable definition")
            }

            do {
                return try ShowItemGetDialogEventListener(params: item!.getJSON(), chainListeners: [(listener: WalkEventListener.self, params: nil)])
            } catch {
                throw error
            }
        default:
            throw EventGeneratorError.EventIdNotFound
        }
    }
}