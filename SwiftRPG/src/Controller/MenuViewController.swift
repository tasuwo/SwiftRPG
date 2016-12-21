//
//  MenuViewController.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/21.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit

class MenuViewController: SceneController {
    fileprivate var model: MenuSceneModel!
    let transition = TransitionBetweenGameAndMenuSceneAnimator()

    override func initializeScene() {
        let scene = MenuScene(size: self.view.bounds.size)
        scene.menuSceneDelegate = self

        self.model = MenuSceneModel()
        self.model.delegate = scene
        self.model.updateItems()
        scene.model = self.model

        self.scene = scene
    }
}

extension MenuViewController: MenuSceneDelegate {
    func didPressBackButton() {
        self.dismiss(animated: true, completion: nil)
    }

    func didSelectedItem(_ indexPath: IndexPath) {
        self.model.selectItem(indexPath)
    }
}

extension MenuViewController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning?
    {
        self.transition.originFrame = self.view.frame
        self.transition.presenting = true
        return self.transition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transition.presenting = false
        return self.transition
    }
}
