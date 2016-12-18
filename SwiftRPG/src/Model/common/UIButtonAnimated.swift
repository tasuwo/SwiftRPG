//
//  common.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/07/16.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

class UIButtonAnimated: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.touchStartAnimation()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.touchEndAnimation()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.touchEndAnimation()
    }

    fileprivate func touchStartAnimation() {
        UIView.animate(withDuration: 0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseIn,
                                   animations: {
                                       () -> Void in
                                       self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95);
                                       self.alpha = 0.7
                                   },
                                   completion: nil)
    }

    fileprivate func touchEndAnimation() {
        UIView.animate(withDuration: 0.1,
                                   delay: 0.0,
                                   options: UIViewAnimationOptions.curveEaseIn,
                                   animations: {
                                       () -> Void in
                                       self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0);
                                       self.alpha = 1
                                   },
                                   completion: nil)
    }
}
