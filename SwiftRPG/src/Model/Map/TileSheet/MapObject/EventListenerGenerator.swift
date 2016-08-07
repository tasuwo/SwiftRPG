//
//  EventListenerGenerator.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

class EventListenerGenerator {
    class func getListenerByID(id: String, directionToParent: DIRECTION?, params: [String]) throws -> EventListener {
        switch id {
        case "talk":
            let parser = TalkBodyParser(talkFileName: params[0])
            var paramsJson = parser?.parse()

            // TODO: Error Handling
            var array = paramsJson!.arrayObject as? [[String:String]]
            let directionString = directionToParent == nil ? "" : directionToParent!.toString
            array?.append(["direction":directionString])
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
            // TODO: Error Handling
            let key: String = params[0]
            let item = ItemTable.get(key)
            if item == nil {
                print("Item not found")
                throw E.error
            }
            let name = item!.name
            let description = item!.description
            let image_name = item!.image_name
            let json = JSON([
                "key": key,
                "name": name,
                "description": description,
                "image_name": image_name
            ])

            do {
                return try ShowItemGetDialogEventListener(params: json, chainListeners: [(listener: WalkEventListener.self, params: nil)])
            } catch {
                throw error
            }
        default:
            throw E.error
        }
    }
}