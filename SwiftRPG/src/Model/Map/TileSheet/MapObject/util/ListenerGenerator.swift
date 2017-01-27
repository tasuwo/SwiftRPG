//
//  LGenerator.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/23.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation

enum ListenerGeneratorError: Error {
    case failed(String)
}

class ListenerGenerator {
    class func generate(properties: [EventProperty]) throws -> Dictionary<TileCoordinate, EventListener> {
        var listenerChains: Dictionary<TileCoordinate, ListenerChain> = [:]

        // イベントプロパティからイベントリスナーを生成する
        // relative Coordinates 毎にリスナーチェーンを保存していく
        for property in properties {
            for relativeCoordinate in property.relativeCoordinates {
                do {
                    let listenerChain = try ListenerContainer.getBy(
                        property.type,
                        directionToParent: property.calcDirection(from: relativeCoordinate),
                        params: property.args)
                    if listenerChains[relativeCoordinate] != nil {
                        listenerChains[relativeCoordinate]? += listenerChain
                    } else {
                        listenerChains[relativeCoordinate] = listenerChain
                    }
                } catch ListenerContainerError.eventIdNotFound {
                    throw ListenerGeneratorError.failed("不正なイベントIDです")
                } catch ListenerContainerError.invalidParams(let string) {
                    throw ListenerGeneratorError.failed(string)
                }
            }
        }

        var listeners: Dictionary<TileCoordinate, EventListener> = [:]
        // イベントリスナーの生成
        for (coordinate, listenerChain) in listenerChains {
            let listenerType = listenerChain.first?.listener
            let params = listenerChain.first?.params
            do {
                let listener = try listenerType?.init(
                    params: params,
                    chainListeners: ListenerChain(listenerChain.dropFirst(1)))
                listeners[coordinate] = listener
            } catch EventListenerError.illegalArguementFormat(let string) {
                throw ListenerGeneratorError.failed("Illegal arguement for listener: " + string)
            } catch EventListenerError.illegalParamFormat(let array) {
                throw ListenerGeneratorError.failed("Illegal parameter for listener: " + array.joined(separator: ","))
            } catch EventListenerError.invalidParam(let string) {
                throw ListenerGeneratorError.failed("Invalid parameter for listener: " + string)
            } catch EventParserError.invalidProperty(let string) {
                throw ListenerGeneratorError.failed("Invalid property for listener: " + string)
            }
        }

        return listeners
    }
}

