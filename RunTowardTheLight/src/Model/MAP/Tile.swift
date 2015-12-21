//
//  Tile.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/08/03.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class Tile {
    static var TILE_SIZE: CGFloat = 32.0
    private let tile_: SKSpriteNode
    private var coordinate_: TileCoordinate!
    private var hasCollision_: Bool
    private var event_: EventDispatcher<AnyObject?>?

    init(coordinate: TileCoordinate, event: EventDispatcher<AnyObject?>?) {
        let x = coordinate.getX()
        let y = coordinate.getY()

        tile_ = SKSpriteNode()
        tile_.size = CGSizeMake(CGFloat(Tile.TILE_SIZE),
                                CGFloat(Tile.TILE_SIZE))
        tile_.position = CGPointMake(CGFloat(x - 1) * Tile.TILE_SIZE,
                                     CGFloat(y - 1) * Tile.TILE_SIZE)
        tile_.anchorPoint = CGPointMake(0.0, 0.0)
        coordinate_ = TileCoordinate(x: x, y: y)
        hasCollision_ = false

        event_ = event
    }

    class func setTileSize(size: CGFloat) {
        Tile.TILE_SIZE = size;
    }

    func getEvent() -> EventDispatcher<AnyObject?>? {
        return event_
    }

    func setEvent(event: EventDispatcher<AnyObject?>) {
        event_ = event
    }

    func setImageWithName(imageName: String) {
        tile_.texture = SKTexture(imageNamed: imageName)
    }

    func setImageWithUIImage(image: UIImage) {
        tile_.texture = SKTexture(image: image)
    }

    func setColor(color: UIColor) {
        tile_.color = color
    }

    func isOn(coordinate: TileCoordinate) -> Bool {
        return (coordinate_.isEqual(coordinate))
    }

    func canPass() -> Bool {
        return !hasCollision_
    }

    func addTo(node: SKSpriteNode) {
        node.addChild(tile_)
    }

    func setCollision() {
        hasCollision_ = true
    }
}