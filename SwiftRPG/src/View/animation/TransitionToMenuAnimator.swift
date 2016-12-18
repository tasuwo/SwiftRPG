//
//  TransitionToMenuAnimator.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/08/16.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import UIKit

class TransitionBetweenGameAndMenuSceneAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration    = 0.6
    var presenting  = true
    var originFrame = CGRect.zero

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?)-> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)

        let toView = toVC?.view!
        let fromView = fromVC?.view!
        toView!.frame = originFrame
        toView!.alpha = 0.0

        let backgroundView = UIView(frame: originFrame)
        backgroundView.backgroundColor = UIColor.black

        transitionContext.containerView.addSubview(backgroundView)
        transitionContext.containerView.addSubview(toView!)

        UIView.animate(
            withDuration: duration/2.0,
            delay: 0.0,
            options: [],
            animations: {
                fromView?.alpha = 0.0
            },
            completion: {
                _ in
                UIView.animate(
                    withDuration: self.duration/2.0,
                    delay: 0.0,
                    options: [],
                    animations: {
                        toView!.alpha = 1.0
                    },
                    completion: {
                        _ in
                        transitionContext.completeTransition(true)
                    }
                )
            }
        )
    }
}
