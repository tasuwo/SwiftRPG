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

struct EventProperty {
    var type: String
    var relativeCoordinates: [TileCoordinate]
    var args: [String]

    // FIXME: 斜め方向に対応していない
    func calcDirection(from relativeCoordinate: TileCoordinate) -> DIRECTION {
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

class EventPropertyParser {
    class func parse(from eventProperties: String) throws -> [EventProperty] {
        let eventProperty = eventProperties.components(separatedBy: "\n")
        var properties: [EventProperty] = []

        for property in eventProperty {
            properties.append(try EventPropertyParser.parseProperty(from: property))
        }

        return properties
    }

    fileprivate class func parseProperty(from eventProperty: String) throws -> EventProperty {
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
}
