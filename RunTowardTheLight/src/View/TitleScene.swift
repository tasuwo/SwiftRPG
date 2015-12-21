//
//  TitleScene.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/07/12.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

protocol TitleSceneDelegate: class {
    func newGameTouched()
}


class TitleScene: SKScene {
    var titleSceneDelegate: TitleSceneDelegate?

    /**
     * シーンが表示された時の処理
     */
    override func didMoveToView(view: SKView) {
        // show background image
        let myImage: UIImage = UIImage(named: "title.png")!
        let myImageView: UIImageView = UIImageView()
        myImageView.image = myImage
        myImageView.frame = CGRectMake(0, 0, self.size.width, self.size.height)
        self.view!.addSubview(myImageView)

        // add START button
        let image = UIImage(named: "start.png")
        let newGameButton = myButton()
        newGameButton.frame = CGRectMake(0, 0, 180, 60)
        newGameButton.addTarget(self, action: "onClickNewGame:", forControlEvents: .TouchUpInside)
        newGameButton.setTitle("New Game")
        newGameButton.setImage(image, forState: .Normal)
        newGameButton.layer.position = CGPoint(x: CGRectGetMidX(self.frame),
                                               y: CGRectGetMidY(self.frame) + 250)
        self.view!.addSubview(newGameButton)

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func onClickNewGame(sender: myButton) {
        titleSceneDelegate?.newGameTouched()
    }
}