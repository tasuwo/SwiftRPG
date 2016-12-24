//
//  UIButton+title.swift
//  SwiftRPG
//
//  Created by tasuku tozawa on 2016/12/24.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    var title: String? {
        get {
            return self.title(for: .normal)
        }
        set(v) {
            UIView.performWithoutAnimation {
                self.setTitle(v, for: .normal)
                self.layoutIfNeeded()
            }
        }
    }
}
