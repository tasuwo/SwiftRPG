//
//  myButton.swift
//  RunTowardTheLight
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
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