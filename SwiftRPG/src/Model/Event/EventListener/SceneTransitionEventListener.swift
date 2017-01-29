//
//  SceneTransitionEventListener.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2017/01/29.
//  Copyright © 2017年 兎澤佑. All rights reserved.
//

import Foundation
import SwiftyJSON
import JSONSchema
import SpriteKit
import PromiseKit

class SceneTransitionEventListener: EventListenerImplement {
    required init(params: JSON?, chainListeners listeners: ListenerChain?) throws {
        try! super.init(params: params, chainListeners: listeners)

        let schema = Schema([
            "type": "object",
            "properties": [
                "map_file_name": ["type": "string"],
                "player_place_coordinate": ["type": "string"],
                "player_direction": [
                    "type":"string",
                    "enum": ["LEFT", "RIGHT", "UP", "DOWN"]
                ]
            ],
            "required": ["map_file_name", "player_place", "player_direction"],
            ])
        let result = schema.validate(params?.rawValue ?? [])
        if result.valid == false {
            throw EventListenerError.illegalParamFormat(result.errors!)
        }

        self.triggerType = .immediate
        self.invoke      = { (sender: GameSceneProtocol?, args: JSON?) -> Promise<Void> in
            let mapFileName = params!["map_file_name"].string!
            let playerCoordinate = self.convertToCoordinate(params!["player_place_coordinate"].string!)
            let playerDirection = DIRECTION.fromString((self.params?["player_direction"].string!)!)

            // Scene transition
            let gameSceneType = MapTable.fromJsonFileName[mapFileName]
            sender?.transitionTo(gameSceneType!, playerCoordinate: playerCoordinate!, playerDirection: playerDirection!)

            return Promise<Void> { fullfill, reject in fullfill() }
        }
    }

    fileprivate func convertToCoordinate(_ string: String) -> TileCoordinate? {
        let coordinates = string.components(separatedBy: "-")
        if let x = Int(coordinates[0]),
           let y = Int(coordinates[1]) {
            return TileCoordinate(x: x, y: y)
        }
        return nil
    }
}

