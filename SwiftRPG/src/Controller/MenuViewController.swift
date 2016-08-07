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
    private var model: MenuSceneModel!
    
    override func loadView() {
        self.view = MenuScene()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let scene = self.view as! MenuScene
        scene.menuSceneDelegate = self
        
        self.model = MenuSceneModel()
        self.model.delegate = scene
        scene.model = self.model

        self.model.updateItems()
    }
    
    // MARK: - MenuSceneDelegate
    
    func didPressBackButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func didSelectedItem(indexPath: NSIndexPath) {
        self.model.selectItem(indexPath)
    }
}