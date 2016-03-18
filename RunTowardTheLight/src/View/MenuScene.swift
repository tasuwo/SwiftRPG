//
//  MenuScene.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

protocol MenuSceneDelegate {
    func didPressBackButton()
}

class MenuScene: UIView {
    var menuSceneDelegate: MenuSceneDelegate?
    
    @IBOutlet var menuView: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var menuListView: UIView!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBAction func didPressBackButton(sender: AnyObject) {
        self.menuSceneDelegate?.didPressBackButton()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        NSBundle.mainBundle().loadNibNamed("MenuScene", owner: self, options: nil)
        menuView.frame = frame
        addSubview(menuView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}