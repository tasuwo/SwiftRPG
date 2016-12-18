//
//  myButton.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/07/29.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

class myButton: UIButton, NSCopying {

    func setTitle(_ title: String?) {
        setTitle(title, for: UIControlState())
        setTitle(title, for: UIControlState.highlighted)
    }

    func copy(with zone: NSZone?) -> Any {
        let newInstance = myButton()

        newInstance.frame = self.frame
        newInstance.backgroundColor = self.backgroundColor
        newInstance.layer.masksToBounds = self.layer.masksToBounds
        newInstance.layer.cornerRadius = self.layer.cornerRadius
        // 文字色
        newInstance.setTitleColor(
        self.titleColor(for: UIControlState()),
        for: UIControlState())
        newInstance.setTitleColor(
        self.titleColor(for: UIControlState.highlighted),
        for: UIControlState.highlighted)

        return newInstance
    }
}
