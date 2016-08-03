//
//  EventListenerGenerator.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

class EventListenerGenerator {
    class func getListenerByID(id: String, params: [String]) -> EventListener? {
        switch id {
        case "talk":
            let parser = TalkBodyParser(talkFileName: params[0])
            return ActivateButtonListener(params: parser?.parse())
        default:
            return nil
        }
    }
}