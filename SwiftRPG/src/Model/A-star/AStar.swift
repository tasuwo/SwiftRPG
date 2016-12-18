//
//  AStar.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class AStar {
    /// 基準ノードのインデックス
    var iBaseNode: Int!
    
    /// 探索対象のマップ
    let map: Map
    
    /// 出発地点のタイル座標
    var departure: TileCoordinate!
    
    /// 目的地点のタイル座標
    var destination: TileCoordinate!
    
    /// 生成したノードを格納しておくリスト
    var nodeList: [Node] = []

    init(map: Map) {
        self.map = map
    }

    ///  A*アルゴリズムの初期化
    ///
    ///  - parameter departure:   出発するタイル座標
    ///  - parameter destination: 目的地のタイル座標
    func initialize(_ departure: TileCoordinate, destination: TileCoordinate) {
        self.departure = departure
        self.destination = destination
        nodeList = []
    }

    ///  A*アルゴリズム開始
    ///
    ///  - returns: 失敗の場合はnil，成功の場合は経路を表したタイルの配列が返る
    func main() -> [TileCoordinate]? {
        /*** 終了判定 ***/
        // initialize されていない
        if departure == nil || destination == nil {
            print("A* is not initialized")
            return nil
        }
        // 目標のタイルが到達不可能，もしくは通行不可能
        if !canPass(destination) {
            print("Target tile cannnot pass or reach")
            return nil
        }

        // 基準ノードの取得
        if nodeList.isEmpty {
            iBaseNode = 0
            nodeList.append(Node(coordinates: departure))
            nodeList[iBaseNode].open(nil, destination: destination)
        } else {
            iBaseNode = chooseBaseNodeIndex()
        }
        // 基準ノードが存在しない場合は，移動失敗
        if iBaseNode == nil {
            print("There are no base node")
            return nil
        }

        // 基準ノードの周囲からOpen可能なノードを探す
        let indexes = searchCanOpenNodeIndexes(iBaseNode)
        // 各ノードをOpenする
        for index in indexes {
            nodeList[index].open(nodeList[iBaseNode], destination: destination)
            // 終了判定
            if nodeList[index].coordinates == destination {
                return getAStarResult()
            }
        }
        // 基準ノードを閉じる
        nodeList[iBaseNode].close()

        return main()
    }

    ///  基準ノードのインデックスを選ぶ
    ///
    ///  - returns: 基準ノードのインデックス
    fileprivate func chooseBaseNodeIndex() -> Int? {
        var min = -1
        var iMinNode: Int? = nil

        // Open なノードを選ぶ
        for i in 0 ..< nodeList.count {
            if nodeList[i].state == Node.STATE.open {
                // スコアが最小のものを選ぶ
                if min == -1 {
                    min = nodeList[i].score
                    iMinNode = i
                    continue
                }
                if nodeList[i].score < min {
                    min = nodeList[i].score
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
    fileprivate func searchCanOpenNodeIndexes(_ iBaseNode: Int) -> [Int] {
        var checkCoordinates: [TileCoordinate] = []
        var indexes: [Int] = []
        let baseX = nodeList[iBaseNode].coordinates.x
        let baseY = nodeList[iBaseNode].coordinates.y

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
            let i_node = nodeList.index() {
                $0.coordinates == coordinate
            }
            if (i_node != nil) {
                if (nodeList[i_node!].state == Node.STATE.none) {
                    indexes.append(i_node!)
                }
            } else {
                // ノードを新たに生成・追加
                let new_node = Node(coordinates: coordinate)
                nodeList.append(new_node)
                indexes.append(nodeList.count - 1)
            }
        }

        return indexes
    }

    ///  探索結果を取得する
    ///
    ///  - returns: 移動経路を表すタイル座標の配列
    fileprivate func getAStarResult() -> [TileCoordinate] {
        var result: [TileCoordinate] = []
        var node: Node

        let index = nodeList.index() {
            $0.coordinates == destination
        }
        node = nodeList[index!]
        while node.parentNode != nil {
            result.append(node.coordinates)
            node = node.parentNode!
        }

        return result.reversed()
    }

    ///  タイルの通行判定
    ///
    ///  - parameter coordinate: タイルの座標
    ///
    ///  - returns: 通行可能なら true, そうでなければ false
    fileprivate func canPass(_ coordinate: TileCoordinate) -> Bool {
        return self.map.canPass(coordinate)
    }
}
