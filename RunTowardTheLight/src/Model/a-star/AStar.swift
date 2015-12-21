//
//  AStar.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class AStar {
    var iBaseNode_: Int!
    let tileSheet_: TileSheet!
    var departure_: TileCoordinate!
    var destination_: TileCoordinate!
    var nodeList_: [Node] = []


    init(sheet: TileSheet) {
        tileSheet_ = sheet
    }


    func initialize(departure: TileCoordinate, destination: TileCoordinate) {
        departure_ = TileCoordinate(x: departure.getX(), y: departure.getY())
        destination_ = TileCoordinate(x: destination.getX(), y: destination.getY())
        nodeList_ = []
    }


    func main() -> [TileCoordinate]? {
        /*** 終了判定 ***/
        // initialize されていない
        if departure_ == nil || destination_ == nil {
            return nil
        }
        // 目標のタイルが到達不可能，もしくは通行不可能
        if !canPass(destination_) {
            return nil
        }

        // 基準ノードの取得
        if nodeList_.isEmpty {
            iBaseNode_ = 0
            nodeList_.append(Node(coordinates: departure_))
            nodeList_[iBaseNode_].open(nil, destination: destination_)
        } else {
            iBaseNode_ = chooseBaseNodeIndex()
        }

        // 基準ノードが存在しない場合は，移動失敗
        if iBaseNode_ == nil {
            return nil
        }

        // 基準ノードの周囲からOpen可能なノードを探す
        let indexes = searchCanOpenNodeIndexes(iBaseNode_)
        // 各ノードをOpenする
        for index in indexes {
            nodeList_[index].open(nodeList_[iBaseNode_], destination: destination_)
            // 終了判定
            if nodeList_[index].getCoordinates().isEqual(destination_) {
                return getAStarResult()
            }
        }
        // 基準ノードを閉じる
        nodeList_[iBaseNode_].close()

        return main()
    }


    func chooseBaseNodeIndex() -> Int? {
        var min = -1
        var iMinNode: Int? = nil

        // Open なノードを選ぶ
        for var i = 0; i < nodeList_.count; i++ {
            if nodeList_[i].getState() == Node.STATE.Open {
                // スコアが最小のものを選ぶ
                if min == -1 {
                    min = nodeList_[i].getScore()
                    iMinNode = i
                    continue
                }
                if nodeList_[i].getScore() < min {
                    min = nodeList_[i].getScore()
                    iMinNode = i
                }
            }
        }
        return iMinNode
    }


    // 基準ノードの周りの Open 可能なノードを探す
    func searchCanOpenNodeIndexes(iBaseNode: Int) -> [Int] {
        var checkCoordinates: [TileCoordinate] = []
        var indexes: [Int] = []
        let baseX = nodeList_[iBaseNode_].getCoordinates().getX()
        let baseY = nodeList_[iBaseNode_].getCoordinates().getY()

        // 基準ノードの上下左右のノードを調べる
        checkCoordinates.append(TileCoordinate(x: baseX - 1, y: baseY))
        checkCoordinates.append(TileCoordinate(x: baseX + 1, y: baseY))
        checkCoordinates.append(TileCoordinate(x: baseX, y: baseY - 1))
        checkCoordinates.append(TileCoordinate(x: baseX, y: baseY + 1))

        for coordinate in checkCoordinates {
            // 通行不可ならば，無視する
            if !canPass(coordinate) {
                continue
            }
            // ノードリストにノードとして存在するか
            let i_node = nodeList_.indexOf() {
                $0.getCoordinates().isEqual(coordinate)
            }
            if (i_node != nil) {
                if (nodeList_[i_node!].getState() == Node.STATE.None) {
                    indexes.append(i_node!)
                }
            } else {
                // ノードを新たに生成・追加
                let new_node = Node(coordinates: coordinate)
                nodeList_.append(new_node)
                indexes.append(nodeList_.count - 1)
            }
        }

        return indexes
    }


    private func getAStarResult() -> [TileCoordinate] {
        var result: [TileCoordinate] = []
        var node: Node

        let index = nodeList_.indexOf() {
            $0.getCoordinates().isEqual(destination_)
        }
        node = nodeList_[index!]
        while node.getParent() != nil {
            result.append(node.getCoordinates())
            node = node.getParent()!
        }

        return result.reverse()
    }


    private func canPass(coordinate: TileCoordinate) -> Bool {
        // タイルが通行可能でない
        if (tileSheet_.canPassTile(coordinate) == nil) {
            return false
        }
        if !tileSheet_.canPassTile(coordinate)! {
            return false
        }

        return true
    }
}