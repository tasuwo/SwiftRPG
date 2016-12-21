//
//  TitleScene.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/07/12.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import UIKit
import SpriteKit
import Foundation

protocol TitleSceneDelegate: class {
    func newGameTouched()
}

class TitleScene: UIView {
    var titleSceneDelegate: TitleSceneDelegate?

    @IBOutlet var titleScene: UIView!
    @IBOutlet weak var startBtn: UIButton!
    
    @IBAction func startBtnPressed(_ sender: AnyObject) {
        self.titleSceneDelegate?.newGameTouched()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        Bundle.main.loadNibNamed("TitleScene", owner: self, options: nil)
        titleScene.frame = frame
        addSubview(titleScene)
        
        titleScene.backgroundColor = UIColor.black
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
