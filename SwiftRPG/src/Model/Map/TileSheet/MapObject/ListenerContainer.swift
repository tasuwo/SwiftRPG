//
//  EventListenerGenerator.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/04.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON

enum ListenerContainerError: Error {
    case eventIdNotFound
    case invalidParams(String)
}

class ListenerContainer {
    class func getBy(_ id: String, directionToParent: DIRECTION?, params: [String]) throws -> ListenerChain {
        switch id {
        case "talk":
            let parser = TalkBodyParser(talkFileName: params[0])
            if parser == nil {
                throw ListenerContainerError.invalidParams("Specified talk file (\(params[0])) is not found. Check your params (\(params.description) format)")
            }
            var paramsJson = parser?.parse()

            // direction を追加
            var array = paramsJson!.arrayObject as? [[String:String]]
            let directionString = directionToParent == nil ? "" : directionToParent!.toString
            array!.append(["direction":directionString!])
            paramsJson = JSON(array!)

            return [
                (listener: ActivateButtonListener.self, params: JSON(["text":"はなす"]) as JSON?),
                (listener: StartTalkEventListener.self, params: paramsJson),
            ]
        case "item":
            let item = ItemTable.get(params[0])
            if item == nil {
                throw ListenerContainerError.invalidParams("Specified item key (\(params[0])) in params(\(params.description)) is not found. Check ItemTable definition")
            }

            return [
                (listener: ItemGetEventListener.self, params: item!.getJSON() as JSON?),
                (listener: ShowEventDialogListener.self, params: JSON(["text":"test"])),
            ]
        default:
            throw ListenerContainerError.eventIdNotFound
        }
    }

    class func getDefault() -> ListenerChain {
        return [
            (listener: RenderDefaultViewEventListener.self, params: nil),
            (listener: WalkEventListener.self, params: nil)
        ]
    }
}
