//
//  GameScene.swift
//  SwiftRPG
//
//  Created by 兎澤佑 on 2015/06/27.
//  Copyright (c) 2015年 兎澤佑. All rights reserved.
//

import SpriteKit
import PromiseKit
import Foundation

/// view controller に処理を delegate する
protocol GameSceneDelegate: class {
    func frameTouched(_ location: CGPoint)
    func gameSceneTouched(_ location: CGPoint)
    func actionButtonTouched()
    func menuButtonTouched()
    func viewUpdated()
    func startBehaviors(_ behaviors: Dictionary<MapObjectId, EventListener>)
    func stopBehaviors()
    func enableWalking()
    func disableWalking()
}

/// ゲーム画面
class GameScene: Scene, GameSceneProtocol {
    var gameSceneDelegate: GameSceneDelegate?
    @IBAction func didPressMenuButton(_ sender: AnyObject) {
        self.gameSceneDelegate?.menuButtonTouched()
    }

    // MARK: GameSceneProtocol Properties

    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var eventDialog: DialogLabel!
    var map: Map?
    var textBox: Dialog!
    var playerInitialCoordinate: TileCoordinate? = nil
    var playerInitialDirection: DIRECTION? = nil

    // MARK: ---
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if map == nil { return }
        let location = touches.first!.location(in: self)
        if self.map!.sheet!.isOnFrame(location) {
            self.gameSceneDelegate?.frameTouched(location)
        } else {
            self.gameSceneDelegate?.gameSceneTouched(location)
        }
    }

    func actionButtonTouched(_ sender: UIButton) {
        self.gameSceneDelegate?.actionButtonTouched()
    }

    override func update(_ currentTime: TimeInterval) {
        self.gameSceneDelegate?.viewUpdated()
    }

    // MARK: GameSceneProtocol Methods

    required init(size: CGSize, playerCoordiante: TileCoordinate, playerDirection: DIRECTION) {
        super.init(size: size)
        self.playerInitialCoordinate = playerCoordiante
        self.playerInitialDirection = playerDirection
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func movePlayer(_ playerActions: [SKAction], tileDeparture: TileCoordinate, tileDestination: TileCoordinate, screenAction: SKAction) -> Promise<Void> {
        let destination = TileCoordinate.getSheetCoordinateFromTileCoordinate(tileDestination)

        // WARNING: Actions of player and sheet should be executed in parallel.
        //          Should specified it?
        return Promise { fulfill, reject in
            let player = self.map?.getObjectByName(objectNameTable.PLAYER_NAME)!
            player?.runAction(playerActions, destination: destination, callback: {
                self.map!.updateObjectPlacement(player!, departure: tileDeparture, destination: tileDestination)
                fulfill()
            })
            self.map?.sheet!.runAction([screenAction], callback: {})
        }
    }

    func moveObject(_ name: String, actions: [SKAction], tileDeparture: TileCoordinate, tileDestination: TileCoordinate) -> Promise<Void> {
        let destination = TileCoordinate.getSheetCoordinateFromTileCoordinate(tileDestination)
        let object = self.map?.getObjectByName(name)!
        return Promise { fulfill, reject in
            object?.runAction(actions, destination: destination, callback: {
                self.map?.updateObjectPlacement(object!, departure: tileDeparture, destination: tileDestination)
                // Enable Events
                self.map?.setEventsOf(object!.id, coordinate: tileDestination)
                fulfill()
            })
        }
    }

    func hideAllButtons() -> Promise<Void> {
        return Promise { fulfill, reject in
            UIView.animate(withDuration: 0.2, animations: {
                self.menuButton.alpha = 0
                self.eventDialog.alpha = 0
                self.actionButton.alpha = 0
                self.textBox.hide()
            }, completion: {
                _ in
                self.menuButton.isHidden = true
                self.eventDialog.isHidden = true
                self.actionButton.isHidden = true
                self.menuButton.alpha = 1
                self.eventDialog.alpha = 1
                self.actionButton.alpha = 1
                fulfill()
            })
        }
    }

    // FIXME: フェードインさせようとすると，menu ボタンがチカチカしてしまう
    func showDefaultButtons() -> Promise<Void> {
        //self.menuButton.alpha = 0
        self.menuButton.isHidden = false

        return Promise { fulfill, reject in
            UIView.animate(
                withDuration: 0.2,
                delay: 0.0,
                options: [.curveLinear],
                animations: { () -> Void in
                    // self.menuButton.alpha = 1
                    // self.menuButton.isHidden = false
                }
            ) { (animationCompleted: Bool) -> Void in fulfill()}
        }
    }

    func showEventDialog() -> Promise<Void> {
        return Promise { fulfill, reject in
            UIView.animate(
                withDuration: 0.2,
                delay: 0.0,
                options: [.curveLinear],
                animations: { () -> Void in
                    self.eventDialog.isHidden = false
                    self.eventDialog.alpha = 1
            }
            ) { (animationCompleted: Bool) -> Void in fulfill()}
        }
    }

    func stopBehaviors() {
        self.gameSceneDelegate?.stopBehaviors()
    }

    func startBehaviors() {
        var behaviors: Dictionary<MapObjectId, EventListener> = [:]
        let objects = self.map?.getAllObjects()
        for object in objects! {
            var listener: EventListener? = nil
            let listenerChain = object.behavior
            let listenerType = listenerChain?.first?.listener
            let params = listenerChain?.first?.params
            do {
                listener = try listenerType?.init(
                    params: params,
                    chainListeners: ListenerChain(listenerChain!.dropFirst(1)))
                listener?.eventObjectId = object.id
                listener?.isBehavior = true
            } catch {
                // TODO
            }

            if let l = listener {
                behaviors[object.id] = l
            }
        }

        self.gameSceneDelegate?.startBehaviors(behaviors)
    }

    func enableWalking() {
        self.gameSceneDelegate?.enableWalking()
    }

    func disableWalking() {
        self.gameSceneDelegate?.disableWalking()
    }

    // MARK: ---
}

