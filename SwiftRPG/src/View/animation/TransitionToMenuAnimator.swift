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

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?)-> NSTimeInterval {
        return duration
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)

        let toView = toVC?.view!
        let fromView = fromVC?.view!
        toView!.frame = originFrame
        toView!.alpha = 0.0

        let backgroundView = UIView(frame: originFrame)
        backgroundView.backgroundColor = UIColor.blackColor()

        transitionContext.containerView()!.addSubview(backgroundView)
        transitionContext.containerView()!.addSubview(toView!)

        UIView.animateWithDuration(
            duration/2.0,
            delay: 0.0,
            options: [],
            animations: {
                fromView?.alpha = 0.0
            },
            completion: {
                _ in
                UIView.animateWithDuration(
                    self.duration/2.0,
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
