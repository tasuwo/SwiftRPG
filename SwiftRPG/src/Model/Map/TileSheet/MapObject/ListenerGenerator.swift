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
    // TODO: Object と Tile のイベントパーサー用メソッドの共通部分を切り出したい
    class func generateEventListenerForTile(properties: [EventProperty]) throws -> EventListener {
        var listeners: Dictionary<TileCoordinate, EventListener> = [:]
        do {
            listeners = try ListenerGenerator.generate(properties: properties)
        } catch {
            // TODO
        }

        if listeners.count > 1 {
            throw EventParserError.invalidProperty("Tile's event propaty has only one coordinate")
        }
        if listeners.count == 1 && listeners.first?.key != TileCoordinate(x:0,y:0) {
            throw EventParserError.invalidProperty("Tile's event propaty has only (0,0)")
        }

        return listeners.first!.value
    }

    class func generateEventObject(properties: [EventProperty], parent: Object) throws -> [Object] {
        var eventObjects: [Object] = []
        var listeners: Dictionary<TileCoordinate, EventListener> = [:]

        // イベントプロパティからイベントリスナーを生成する
        do {
            listeners = try ListenerGenerator.generate(properties: properties)
        } catch {
            // TODO
        }

        // eventObject は relativeCoordinate 毎に作成する
        for (coordinate, listener) in listeners {
            // TODO: 名前をどうするか
            let eventObject: Object = Object(
                name: "",
                position: TileCoordinate.getSheetCoordinateFromTileCoordinate(parent.coordinate + coordinate),
                images: nil)

            eventObject.events.append(listener)
            // TODO: parent に children を登録すべきでは？
            eventObject.parent = parent
            eventObjects.append(eventObject)
        }
        
        return eventObjects
    }

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
                    chainListeners: ListenerChain(listenerChain.dropFirst(1)) + ListenerContainer.getDefault())
                listeners[coordinate] = listener
            } catch {
                // TODO
            }
        }

        return listeners
    }
}

