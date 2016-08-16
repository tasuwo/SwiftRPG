//
//  ItemCell.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

class ItemCell: UICollectionViewCell {
    @IBOutlet var cellView: UICollectionViewCell!
    @IBOutlet weak var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NSBundle.mainBundle().loadNibNamed("ItemCell", owner: self, options: nil)
        imageView.backgroundColor = UIColor.blackColor()
        imageView.alpha = 0.5
        addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}