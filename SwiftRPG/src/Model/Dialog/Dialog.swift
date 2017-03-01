//
//  Dialog.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2015/08/10.
//  Copyright © 2015年 兎澤佑. All rights reserved.
//

import Foundation
import SpriteKit
import PromiseKit
import UIKit

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class Dialog {
    let FONT_SIZE: CGFloat          = 14.0
    let FONT_WIDTH_MARGIN: CGFloat  = 1.0
    let FONT_HEIGHT_MARGIN: CGFloat = 5.0
    let PADDING_WIDTH: CGFloat      = 20.0
    let PADDING_HEIGHT: CGFloat     = 14.0
    let MARGIN: CGFloat             = 30.0
    let VIEW_TEXT_TIME: CGFloat     = 0.1
    let BUTTON_SIZE: CGFloat        = 10.0

    let textBox: SKShapeNode!
    var boxWidth: CGFloat!
    var boxHeight: CGFloat!
    var textRegionWidth: CGFloat!
    var textRegionHeight: CGFloat!
    let charRegionWidth: CGFloat!
    let charRegionHeight: CGFloat!

    let nextButton: SKSpriteNode!
    let buttonLoop: SKAction!

    var rowNum: CGFloat!
    var colNum: CGFloat!

    fileprivate let frameWidth: CGFloat!
    fileprivate let frameHeight: CGFloat!

    var characterIcon: SKSpriteNode!
    let CHAR_ICON_SIZE: CGFloat = 150.0
    let ICON_MARGIN: CGFloat = 10.0

    fileprivate let CHAR_LABEL_NAME = "text"
    
    static let NEWLINE_CHAR: Character = "嬲"
    
    enum POSITION {
        case top, bottom, middle
    }

    enum TALK_SIDE {
        case left, right, middle
    }

    init(frame_width: CGFloat, frame_height: CGFloat) {
        frameWidth = frame_width
        frameHeight = frame_height

        boxWidth = frameWidth - 10
        boxHeight = 150.0

        // 文字1文字の描画幅
        charRegionWidth = FONT_SIZE + FONT_WIDTH_MARGIN
        charRegionHeight = FONT_SIZE + FONT_HEIGHT_MARGIN

        // テキスト描画領域のサイズ
        textRegionWidth = boxWidth - PADDING_WIDTH * 2
        textRegionHeight = boxHeight - PADDING_HEIGHT * 2

        // テキスト描画領域内に描画可能な最大文字数，行数
        rowNum = ceil(textRegionWidth / charRegionWidth)
        colNum = ceil(textRegionHeight / charRegionHeight)

        // テキスト描画領域のサイズ最適化
        textRegionWidth = rowNum * charRegionWidth
        textRegionHeight = colNum * charRegionHeight - FONT_HEIGHT_MARGIN

        // テキストボックスのサイズ最適化
        // box_width_  = text_region_width_  + PADDING*2
        boxHeight = textRegionHeight + PADDING_HEIGHT * 2 + BUTTON_SIZE

        // テキストボックスサイズを求める
        let box_shape = CGRect(x: 0, y: 0, width: boxWidth, height: boxHeight)
        textBox = SKShapeNode(rect: box_shape, cornerRadius: 10)
        textBox.fillColor = SKColor.black
        textBox.strokeColor = SKColor.white
        textBox.lineWidth = 2.0
        textBox.zPosition = zPositionTable.DIALOG
        textBox.position = CGPoint(x: frame_width / 2 - boxWidth / 2,
                                        y: frame_height / 2 - boxHeight / 2)

        // ページ送りボタンの設置
        nextButton = SKSpriteNode(
            color: UIColor.white,
            size: CGSize(width: BUTTON_SIZE, height: BUTTON_SIZE))
        nextButton.position = CGPoint(
            x: PADDING_WIDTH + textRegionWidth,
            y: PADDING_HEIGHT)
        let fadeout = SKAction.fadeAlpha(to: 0.0, duration: 0.0)
        let fadein = SKAction.fadeAlpha(to: 1.0, duration: 0.0)
        let delay = SKAction.wait(forDuration: TimeInterval(0.5))
        buttonLoop = SKAction.repeatForever(
            SKAction.sequence([fadein, delay, fadeout, delay]))
        nextButton.alpha = 0.0
        nextButton.position.y = PADDING_HEIGHT
        textBox.addChild(nextButton)

        // キャラクター画像表示
        characterIcon = SKSpriteNode()
        characterIcon.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        characterIcon.size = CGSize(
            width: CHAR_ICON_SIZE - ICON_MARGIN * 2,
            height: boxHeight - ICON_MARGIN * 2)
        characterIcon.zPosition = zPositionTable.DIALOG_ICON
        characterIcon.color = UIColor.black
        characterIcon.position.y = PADDING_HEIGHT // FONT_SIZE + ICON_MARGIN
        textBox.addChild(characterIcon)
    }

    ///  ダイアログを描画する上下位置を設定する
    ///
    ///  - parameter position: 描画する場所
    func setPositionY(_ upDownPosition: POSITION) {
        switch upDownPosition {
        case .top:    textBox.position.y = frameHeight - boxHeight - 3
        case .middle: textBox.position.y = frameHeight / 2 - boxHeight / 2
        case .bottom: textBox.position.y = 3
        }
    }

    ///  キャラクターを描画する左右位置を設定する
    ///  テキストの anchor point が左上ではなくて真上なので FONT_SIZE/2 を足す
    ///
    ///  - parameter sidePosition: キャラクターの描画位置
    func setPositionX(_ sidePosition: TALK_SIDE) {
        self.textBox.position.x = frameWidth / 2 - boxWidth / 2
        
        switch sidePosition {
        case .left:
            rowNum                   = ceil((frameWidth - PADDING_WIDTH * 2 - CHAR_ICON_SIZE) / charRegionWidth)
            textRegionWidth          = rowNum * charRegionWidth
            nextButton.position.x    = frameWidth - PADDING_WIDTH * 3 / 2
            characterIcon.position.x = ICON_MARGIN
            characterIcon.isHidden     = false
        case .right:
            rowNum                   = ceil((frameWidth - PADDING_WIDTH - CHAR_ICON_SIZE) / charRegionWidth)
            textRegionWidth          = rowNum * charRegionWidth
            nextButton.position.x    = frameWidth - CHAR_ICON_SIZE - PADDING_WIDTH * 3 / 2
            characterIcon.position.x = textRegionWidth + ICON_MARGIN // + PADDING_WIDTH 
            characterIcon.isHidden     = false
        case .middle:
            rowNum                   = ceil((frameWidth - PADDING_WIDTH * 2) / charRegionWidth)
            textRegionWidth          = rowNum * charRegionWidth
            nextButton.position.x    = frameWidth - PADDING_WIDTH * 3 / 2
            characterIcon.isHidden     = true
        }
    }

    ///  テキスト領域の anchor point を取得する
    ///
    ///  - parameter sidePosition: テキスト領域の位置
    ///
    ///  - returns: anchor point
    fileprivate func getAnchorPositionOfTextRegion(_ sidePosition: TALK_SIDE) -> CGPoint {
        switch sidePosition {
        case .left:
            return CGPoint(x: FONT_SIZE / 2 + frameWidth - PADDING_WIDTH - textRegionWidth, y: boxHeight - FONT_SIZE - PADDING_HEIGHT)
        case .right:
            return CGPoint(x: FONT_SIZE / 2 + PADDING_WIDTH, y: boxHeight - FONT_SIZE - PADDING_HEIGHT)
        case .middle:
            return CGPoint(x: FONT_SIZE / 2 + PADDING_WIDTH, y: boxHeight - FONT_SIZE - PADDING_HEIGHT)
        }
    }

    ///  シーンにテキストボックスを追加する
    ///
    ///  - parameter scene: テキストボックスを追加するシーン
    func addTo(_ scene: SKScene) {
        scene.addChild(textBox)
    }

    ///  テキストボックスを非表示にする
    func hide() {
        textBox.isHidden = true
    }

    ///  テキストボックスを表示する
    ///
    ///  - parameter position: 表示位置
    func show(_ position: POSITION? = nil, duration: Double) -> Promise<Void> {
        return Promise { fulfill, reject in
            self.setPositionY(position ?? .bottom)
            textBox.alpha = 0.0
            textBox.isHidden = false
            textBox.run(SKAction.fadeAlpha(to: 1, duration: duration), completion: { fulfill() })
        }
    }

    ///  テキストボックスを隠す
    ///
    ///  - parameter position: 表示位置
    func hide(duration: Double) -> Promise<Void> {
        return Promise { fulfill, reject in
            textBox.alpha = 1.0
            textBox.isHidden = true
            textBox.run(SKAction.fadeAlpha(to: 0, duration: duration), completion: { fulfill() })
        }
    }

    ///  テキストを描画する
    ///
    ///  - parameter text:     描画するテキスト
    ///  - parameter talkSide: テキスト描画位置
    func drawText(_ talkerImageName: String?, body: String, side: TALK_SIDE) {
        var iDrawingFont: CGFloat = 0     // 描画位置を決める
        var nDrawingFont: CGFloat = 0     // 描画している文字が何番目か決める

        // キャラクター画像表示
        if let imageName = talkerImageName {
            characterIcon.texture = SKTexture(imageNamed: imageName)
        }
        // 先送りボタン非表示
        nextButton.removeAllActions()
        nextButton.alpha = 0.0
        // 既に表示されている文字クリア
        clearText()

        for character in body.characters {
            // テキスト描画領域内のanchorpoint
            // 左上から描画する
            self.setPositionX(side)
            let anchor = self.getAnchorPositionOfTextRegion(side)

            // 改行文字の判定
            if character == Dialog.NEWLINE_CHAR {
                iDrawingFont = ceil(iDrawingFont / rowNum) * rowNum
                continue
            }

            // 何行目の何文字目を描画するか(0〜)
            var nLine = floor(iDrawingFont / rowNum)
            var nChar = floor(iDrawingFont.truncatingRemainder(dividingBy: rowNum))

            if iDrawingFont / rowNum + 1 > colNum {
                // 行数が超えていたら次ページ
                // TODO: 一行ずつ文字送りするなど，もっと良いやり方がありそう
                textBox.enumerateChildNodes(withName: CHAR_LABEL_NAME, using: {
                    node, sotp in

                    let delay = SKAction.wait(
                    forDuration: TimeInterval(self.VIEW_TEXT_TIME * nDrawingFont)
                    )
                    let fadeout = SKAction.fadeAlpha(to: 0.0, duration: 0.0)
                    let seq = SKAction.sequence([delay, fadeout])
                    node.run(seq)
                })
                nDrawingFont += 1
                iDrawingFont = 0
                nLine = 0
                nChar = 0
            }

            let char = SKLabelNode(text: String(character))
            char.fontSize = FONT_SIZE
            char.name = CHAR_LABEL_NAME
            char.position = CGPoint(x: anchor.x + nChar * charRegionWidth,
                                        y: anchor.y - nLine * charRegionHeight)
            char.alpha = 0.0
            textBox.addChild(char)
            
            let delay = SKAction.wait(forDuration: TimeInterval(VIEW_TEXT_TIME * nDrawingFont))
            let fadein = SKAction.fadeAlpha(by: 1.0, duration: 0.0)
            let sound = SKAction.playSoundFileNamed("talk.wav", waitForCompletion: false)
            let seq = SKAction.sequence([delay, fadein, sound])
            char.run(seq)

            iDrawingFont += 1
            nDrawingFont += 1
        }

        // 先送りボタン表示
        let delay = SKAction.wait(forDuration: TimeInterval(VIEW_TEXT_TIME * nDrawingFont))
        nextButton.run(SKAction.sequence([delay, buttonLoop]))
    }

    ///  描画したテキストを削除する
    func clearText() {
        var allNode: [SKNode] = []
        textBox.enumerateChildNodes(withName: CHAR_LABEL_NAME, using: { node, sotp in allNode.append(node) })
        for child in textBox.children {
            child.removeAllActions()
        }
        textBox.removeChildren(in: allNode)
    }

    func clean() {
        // キャラクター画像削除
        characterIcon.texture = nil
        // 先送りボタン非表示
        nextButton.removeAllActions()
        nextButton.alpha = 0.0
        // 既に表示されている文字クリア
        clearText()
    }
}
