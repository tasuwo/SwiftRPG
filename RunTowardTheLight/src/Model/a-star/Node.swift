//
//  Node.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/08/08.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Node {

    enum STATE {
        case None, Open, Closed
    }

    private var state_: STATE!
    //!< ステータス
    private var coordinates_: TileCoordinate!
    //!< XY座標
    private var parentNode_: Node?
    //!< 親ノード
    private var heuristicCost_: Int!
    //!< 推定コスト
    private var moveCost_: Int!
    //!< 移動コスト

    init(coordinates: TileCoordinate) {
        state_ = STATE.None
        coordinates_ = TileCoordinate(x: coordinates.getX(),
                                      y: coordinates.getY())
    }

    func open(parentNode: Node?, destination: TileCoordinate) {
        // ノードをOpen状態にする
        self.state_ = STATE.Open

        // 実コストを求める. スタート地点だった場合には 0
        if parentNode == nil {
            moveCost_ = 0
        } else {
            moveCost_ = parentNode!.getMoveCost() + 1
        }

        // 推定コストを求める
        let dx = abs(destination.getX() - coordinates_.getX())
        let dy = abs(destination.getY() - coordinates_.getY())
        heuristicCost_ = dx + dy

        // 親ノードを保持する
        parentNode_ = parentNode
    }

    func close() {
        self.state_ = STATE.Closed
    }

    func isPositioned(coordinates: TileCoordinate) -> Bool {
        if coordinates_.isEqual(coordinates) {
            return true
        } else {
            return false
        }
    }

    func getState() -> STATE {
        return state_
    }

    func getScore() -> Int {
        return heuristicCost_ + moveCost_
    }

    func getMoveCost() -> Int {
        return moveCost_
    }

    func getCoordinates() -> TileCoordinate {
        return coordinates_
    }

    func getParent() -> Node? {
        return parentNode_
    }
}