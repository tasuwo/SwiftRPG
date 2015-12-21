//
//  TitleViewController.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/07/15.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit

class TitleViewController: UIViewController, TitleSceneDelegate {
    var isInitializedScene: Bool = false

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !isInitializedScene {
            let scene = TitleScene(size: self.view.frame.size)
            scene.titleSceneDelegate = self

            let skView = self.view as! SKView
            skView.presentScene(scene)

            isInitializedScene = true
        }
    }

    func newGameTouched() {
        let gameViewController: UIViewController = GameViewController()
        self.presentViewController(gameViewController, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}