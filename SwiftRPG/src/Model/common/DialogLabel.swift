//
//  DialogLabel.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

class DialogLabel: UILabel {
    
    let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    override func drawText(in rect: CGRect) {
        let newRect = UIEdgeInsetsInsetRect(rect, padding)
        super.drawText(in: newRect)
    }
    
    override var intrinsicContentSize : CGSize {
        var intrinsicContentSize = super.intrinsicContentSize
        intrinsicContentSize.height += padding.top + padding.bottom
        intrinsicContentSize.width  += padding.left + padding.right
        return intrinsicContentSize
    }
}
