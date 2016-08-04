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
    class func getListenerByID(id: String, eventPlacedDirection: DIRECTION?, params: [String]) -> EventListener? {
        switch id {
        case "talk":
            let parser = TalkBodyParser(talkFileName: params[0])
            var paramsJson = parser?.parse()

            if let direction = eventPlacedDirection {
                // TODO: error handling
                var array = paramsJson!.arrayObject as? [[String:String]]
                array?.append(["direction":direction.toString])
                paramsJson = JSON(array!)
            }

            return ActivateButtonListener(params: paramsJson, nextEventListener: WalkEventListener(params: nil))
        case "item":
            let key: String = params[0]
            let item = ItemTable.get(key)
            if item == nil {
                print("Item not found")
                return nil
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
            return ShowItemGetDialogEventListener(params: json, nextEventListener: WalkEventListener(params: nil))
        default:
            return nil
        }
    }
}