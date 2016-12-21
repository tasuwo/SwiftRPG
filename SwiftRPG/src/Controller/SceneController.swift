//
//  SceneController.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/22.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

class SceneController: UIViewController {
    var viewInitiated: Bool = false
    var scene: Scene!

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isMultipleTouchEnabled = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if (!viewInitiated) {
            self.initializeScene()

            self.view = self.scene.sceneView
            let view = self.view as! SKView
            view.presentScene(self.scene)
            
            self.viewInitiated = true
        }
    }

    func initializeScene() {
        let scene = Scene()
        self.scene = scene
    }
}
