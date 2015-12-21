//
//  common.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2015/07/16.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

class myButton: UIButton, NSCopying {

    func setTitle(title: String?) {
        setTitle(title, forState: UIControlState.Normal)
        setTitle(title, forState: UIControlState.Highlighted)
    }

    func copyWithZone(zone: NSZone) -> AnyObject {
        let newInstance = myButton()

        newInstance.frame = self.frame
        newInstance.backgroundColor = self.backgroundColor
        newInstance.layer.masksToBounds = self.layer.masksToBounds
        newInstance.layer.cornerRadius = self.layer.cornerRadius
        // 文字色
        newInstance.setTitleColor(
        self.titleColorForState(UIControlState.Normal),
        forState: UIControlState.Normal)
        newInstance.setTitleColor(
        self.titleColorForState(UIControlState.Highlighted),
        forState: UIControlState.Highlighted)

        return newInstance
    }
}

class UIButtonAnimated: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init() {
        self.init(frame: CGRectMake(0, 0, 100, 100))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        self.touchStartAnimation()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        self.touchEndAnimation()
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        self.touchEndAnimation()
    }

    private func touchStartAnimation() {
        UIView.animateWithDuration(0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseIn,
                                   animations: {
                                       () -> Void in
                                       self.transform = CGAffineTransformMakeScale(0.95, 0.95);
                                       self.alpha = 0.7
                                   },
                                   completion: nil)
    }

    private func touchEndAnimation() {
        UIView.animateWithDuration(0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseIn,
                                   animations: {
                                       () -> Void in
                                       self.transform = CGAffineTransformMakeScale(1.0, 1.0);
                                       self.alpha = 1
                                   },
                                   completion: nil)
    }

}
