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
    /// 基準ノードのインデックス
    var iBaseNode_: Int!
    
    /// 探索対象のマップ
    let map_: Map
    
    /// 出発地点のタイル座標
    var departure_: TileCoordinate!
    
    /// 目的地点のタイル座標
    var destination_: TileCoordinate!
    
    /// 生成したノードを格納しておくリスト
    var nodeList_: [Node] = []

    init(map: Map) {
        map_ = map
    }


    ///  A*アルゴリズムの初期化
    ///
    ///  - parameter departure:   出発するタイル座標
    ///  - parameter destination: 目的地のタイル座標
    func initialize(departure: TileCoordinate, destination: TileCoordinate) {
        departure_ = departure
        destination_ = destination
        nodeList_ = []
    }


    ///  A*アルゴリズム開始
    ///
    ///  - returns: 失敗の場合はnil，成功の場合は経路を表したタイルの配列が返る
    func main() -> [TileCoordinate]? {
        /*** 終了判定 ***/
        // initialize されていない
        if departure_ == nil || destination_ == nil {
            print("A* is not initialized")
            return nil
        }
        // 目標のタイルが到達不可能，もしくは通行不可能
        if !canPass(destination_) {
            print("Target tile cannnot pass or reach")
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
            print("There are no base node")
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


    ///  基準ノードのインデックスを選ぶ
    ///
    ///  - returns: 基準ノードのインデックス
    private func chooseBaseNodeIndex() -> Int? {
        var min = -1
        var iMinNode: Int? = nil

        // Open なノードを選ぶ
        for i in 0 ..< nodeList_.count {
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


    ///  基準ノードの周りの Open 可能なノードを探す
    ///
    ///  - parameter iBaseNode: 基準ノードのインデックス
    ///
    ///  - returns: open 可能なノードのインデックス
    private func searchCanOpenNodeIndexes(iBaseNode: Int) -> [Int] {
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


    ///  探索結果を取得する
    ///
    ///  - returns: 移動経路を表すタイル座標の配列
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


    ///  タイルの通行判定
    ///
    ///  - parameter coordinate: タイルの座標
    ///
    ///  - returns: 通行可能なら true, そうでなければ false
    private func canPass(coordinate: TileCoordinate) -> Bool {
        return self.map_.canPass(coordinate)
    }
}