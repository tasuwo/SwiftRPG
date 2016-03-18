//
//  MenuViewController.swift
//  RunTowardTheLight
//
//  Created by 兎澤佑 on 2016/03/18.
//  Copyright © 2016年 兎澤佑. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UIViewController, MenuSceneDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = MenuScene(frame: self.view.frame)
        view.menuSceneDelegate = self
        self.view.addSubview(view)
    }
    
    func didPressBackButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}