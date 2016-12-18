//
//  TileSet.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/02/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

enum TileSetError: Error {
    case failedToCrop
}

/// タイルセット : 1画像ファイル内のタイル群 = 1タイルセットに対応
class TileSet {
    /// タイルセットを一意に識別するID
    fileprivate let tileSetID: Int!
    
    /// 画像ファイル名
    fileprivate let imageName: String!
    
    /// セット内のタイル数
    fileprivate let count: Int!
    
    /// 一番若いタイルID
    fileprivate let firstTileID: Int!
    
    /// タイルセット(画像ファイル)の横幅
    fileprivate let imageWidth: Int!
    
    /// タイルセット(画像ファイル)の縦幅
    fileprivate let imageHeight: Int!
    
    /// タイルセット内の各タイルの横幅
    fileprivate let tileWidth: Int!
    
    /// タイルセット内の各タイルの縦幅
    fileprivate let tileHeight: Int!
    
    init?(id: Int,
          imageName: String,
          nTile: Int,
          firstTileID: Int,
          width: Int,
          height: Int,
          tileWidth: Int,
          tileHeight: Int) {
        self.tileSetID = id
        self.imageName = imageName
        self.count = nTile
        self.firstTileID = firstTileID
        self.imageWidth = width
        self.imageHeight = height
        self.tileWidth = tileWidth
        self.tileHeight = tileHeight
    }

    ///  タイルの画像を，タイルセット(1画像ファイル)から切り出し，返す
    ///
    ///  - parameter tileSetID: 対象タイルが含まれるタイルセットID
    ///  - parameter tileID:    対象タイルのタイルID
    ///
    ///  - throws: otherError
    ///
    ///  - returns: タイル画像
    func cropTileImage(_ tileID: Int) throws -> UIImage {
        let tileSetRows = self.imageWidth / self.tileWidth
        let firstTileID = self.firstTileID
        var iTargetTileInSet: Int
        
        // ID は左上から順番
        // TODO: tileSet の中に tileID が含まれていない場合の validation
        if firstTileID! >= tileID {
            iTargetTileInSet = firstTileID! - tileID
        } else {
            iTargetTileInSet = tileID - 1
        }
        
        // 対象タイルの，タイルセット内における位置(行数，列数)を調べる
        let targetCol: Int
        let targetRow: Int
        if iTargetTileInSet == 0 {
            targetCol = 1
            targetRow = 1
        } else {
            targetRow = Int(iTargetTileInSet % tileSetRows) + 1
            targetCol = Int(iTargetTileInSet / tileSetRows) + 1
        }
        
        // 画像の切り抜き
        let tileSize = CGRect(
            x: CGFloat(tileWidth) * CGFloat(targetRow - 1),
            y: CGFloat(tileHeight) * CGFloat(targetCol - 1),
            width: CGFloat(tileWidth),
            height: CGFloat(tileHeight))
        if let image = UIImage(named: self.imageName),
            let cropCGImageRef = image.cgImage?.cropping(to: tileSize) {
                return UIImage(cgImage: cropCGImageRef)
        } else {
            throw TileSetError.failedToCrop
        }
    }
}
