//
//  TileSet.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/02/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

/// タイルセット : 1画像ファイル内のタイル群 = 1タイルセットに対応
class TileSet {
    /// タイルセットを一意に識別するID
    private let tileSetID: Int!
    
    /// 画像ファイル名
    private let imageName: String!
    
    /// セット内のタイル数
    private let count: Int!
    
    /// 一番若いタイルID
    private let firstTileID: Int!
    
    /// タイルセット(画像ファイル)の横幅
    private let imageWidth: Int!
    
    /// タイルセット(画像ファイル)の縦幅
    private let imageHeight: Int!
    
    /// タイルセット内の各タイルの横幅
    private let tileWidth: Int!
    
    /// タイルセット内の各タイルの縦幅
    private let tileHeight: Int!
    
    init?(
        id: Int,
        imageName: String,
        nTile: Int,
        firstTileID: Int,
        width: Int,
        height: Int,
        tileWidth: Int,
        tileHeight: Int
    ) {
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
    ///  - throws:
    ///
    ///  - returns: タイル画像
    func cropTileImage(tileID: Int) throws -> UIImage {
        let tileSetRows = self.imageWidth / self.tileWidth
        let firstTileID = self.firstTileID
        var iTargetTileInSet: Int
        
        // ID は左上から順番
        // TODO: tileSet の中に tileID が含まれていない場合の validation
        if firstTileID >= tileID {
            iTargetTileInSet = firstTileID - tileID
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
        let tileSize = CGRectMake(
            CGFloat(tileWidth) * CGFloat(targetRow - 1),
            CGFloat(tileHeight) * CGFloat(targetCol - 1),
            CGFloat(tileWidth),
            CGFloat(tileHeight))
        if let image = UIImage(named: self.imageName),
            let cropCGImageRef = CGImageCreateWithImageInRect(image.CGImage, tileSize) {
                return UIImage(CGImage: cropCGImageRef)
        } else {
            throw ParseError.otherError("画像の切り抜きに失敗")
        }
    }
}