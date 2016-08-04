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

            return ActivateButtonListener(params: paramsJson)
        default:
            return nil
        }
    }
}