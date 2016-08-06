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

/// A*アルゴリズムのためのノード
class Node {

    enum STATE {
        case None, Open, Closed
    }

    /// ステータス
    private var state_: STATE!
    
    /// XY座標
    private var coordinates_: TileCoordinate!
    
    /// 親ノード
    private var parentNode_: Node!
    
    /// 推定コスト
    private var heuristicCost_: Int!
    
    /// 移動コスト
    private var moveCost_: Int!

    
    ///  コンストラクタ
    ///
    ///  - parameter coordinates: タイル座標
    init(coordinates: TileCoordinate) {
        state_ = STATE.None
        coordinates_ = TileCoordinate(x: coordinates.x,
                                      y: coordinates.y)
    }

    
    ///  ノードを開く
    ///
    ///  - parameter parentNode:  親ノード
    ///  - parameter destination: 目的地のタイル座標
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
        let dx = abs(destination.x - coordinates_.x)
        let dy = abs(destination.y - coordinates_.y)
        heuristicCost_ = dx + dy

        // 親ノードを保持する
        parentNode_ = parentNode
    }

    
    ///  ノードを閉じる
    func close() {
        self.state_ = STATE.Closed
    }

    
    ///  ノードの現在位置を確認する
    ///
    ///  - parameter coordinates: 確認する座標
    ///
    ///  - returns: 指定した座標にノードが存在しなければ false, 存在すれば true
    func isPositioned(coordinates: TileCoordinate) -> Bool {
        if coordinates_ == coordinates {
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