//
//  EventPropertyParser.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/25.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation

enum EventParserError: Error {
    case invalidProperty(String)
}

class EventPropertyParser {
    struct EventProperty {
        var type: String
        var relativeCoordinates: [TileCoordinate]
        var args: [String]
    }

    class func parse(from eventProperty: String) throws -> EventProperty {
        var property = EventProperty(type: "", relativeCoordinates: [], args: [])

        // プロパティを (イベント種別, イベント配置, イベント引数) に分割
        // ex) talk,{(0,-1),(-1,0),(1,0)},params
        let eventCoordinatesPattern = "(\\(-?[0-9]+,-?[0-9]+\\),?)+"
        let matchedEventCoordinatesSets = EventPropertyParser.matches(for: eventCoordinatesPattern, in: eventProperty)
        if matchedEventCoordinatesSets == [] {
            throw EventParserError.invalidProperty("Invalid Property: \(eventProperty)")
        }
        let eventCoordinatesSetString = matchedEventCoordinatesSets[0]

        let matchedEventCoordinates = self.matches(for: "\\(-?[0-9]+,-?[0-9]+\\)", in: eventCoordinatesSetString)
        for eventCoordinateString in matchedEventCoordinates {
            property.relativeCoordinates.append(TileCoordinate.parse(from: eventCoordinateString))
        }

        let params = eventProperty.replacingOccurrences(of: "{"+eventCoordinatesSetString+"},", with: "")
        let tmp = params.components(separatedBy: ",")
        property.type = tmp[0]
        property.args = Array(tmp.dropFirst())

        return property
    }

    // TODO: Object と Tile のイベントパーサー用メソッドの共通部分を切り出したい
    class func generateEventListenerForTile(property: EventProperty) throws -> EventListener {
        if property.relativeCoordinates.count > 1 {
            throw EventParserError.invalidProperty("Tile's event propaty has only one coordinate")
        }
        if property.relativeCoordinates.count == 1 && property.relativeCoordinates[0] != TileCoordinate(x:0,y:0) {
            throw EventParserError.invalidProperty("Tile's event propaty has only (0,0)")
        }

        let direction = calcDirection(from: property.relativeCoordinates[0])
        let event: EventListener
        do {
            event = try EventListenerGenerator.getListenerByID(property.type, directionToParent: direction, params: property.args)
        } catch {
            throw error
        }

        return event
    }

    class func generateEventObject(property: EventProperty, parent: Object) throws -> [Object] {
        var eventObjects: [Object] = []

        for relativeCoordinate in property.relativeCoordinates {
            let direction = calcDirection(from: relativeCoordinate)
            let event: EventListener
            do {
                event = try EventListenerGenerator.getListenerByID(property.type, directionToParent: direction, params: property.args)
            } catch {
                throw error
            }

            // TODO: 名前をどうするか
            let eventObject: Object = Object(
                name: "",
                position: TileCoordinate.getSheetCoordinateFromTileCoordinate(parent.coordinate + relativeCoordinate),
                images: nil)
            eventObject.events.append(event)
            // TODO: parent に children を登録すべきでは？
            eventObject.parent = parent
            eventObjects.append(eventObject)
        }

        return eventObjects
    }

    fileprivate class func matches(for regex: String, in text: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { nsString.substring(with: $0.range)}
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }

    // FIXME: 斜め方向に対応していない
    fileprivate class func calcDirection(from relativeCoordinate: TileCoordinate) -> DIRECTION {
        if relativeCoordinate.x > 0 {
            return .left
        } else if relativeCoordinate.x < 0 {
            return .right
        } else if relativeCoordinate.y > 0 {
            return .down
        } else if relativeCoordinate.y < 0 {
            return .up
        }

        // FIXME: 上記のいずれにもマッチしなかった場合にどうするか
        return .down
    }
}
