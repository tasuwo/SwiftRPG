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
    enum STATE { case None, Open, Closed }
    private var state_:          STATE!          //!< ステータス
    private var coordinates_:    TileCoordinate! //!< XY座標
    private var parent_node_:    Node?           //!< 親ノード
    private var heuristic_cost_: Int!            //!< 推定コスト
    private var move_cost_:      Int!            //!< 移動コスト
    
    init(coordinates: TileCoordinate){
        state_       = STATE.None
        coordinates_ = TileCoordinate(x: coordinates.getX(),
                                      y: coordinates.getY())
    }
    
    func openNode(parent_node: Node?, destination: TileCoordinate){
        // ノードをOpen状態にする
        self.state_ = STATE.Open
        // 実コストを求める. スタート地点だった場合には 0
        if parent_node == nil { move_cost_ = 0 }
        else { move_cost_ = parent_node!.getMoveCost() + 1 }
        // 推定コストを求める
        let dx = abs(destination.getX() - coordinates_.getX())
        let dy = abs(destination.getY() - coordinates_.getY())
        heuristic_cost_ = dx + dy
        // 親ノードを保持する
        parent_node_ = parent_node
    }
    
    func closeNode(){
        self.state_ = STATE.Closed
    }
    
    func isPositioned(coordinates: TileCoordinate) -> Bool {
        if coordinates_.isEqual(coordinates) { return true }
        else { return false }
    }
    
    func getState()->STATE{
        return self.state_
    }
    
    func getScore()->Int{
        return heuristic_cost_ + move_cost_
    }
    
    func getMoveCost()->Int{
        return self.move_cost_
    }
    
    func getCoordinates()->TileCoordinate{
        return self.coordinates_
    }
    
    func getParent() -> Node?{
        return self.parent_node_
    }
}