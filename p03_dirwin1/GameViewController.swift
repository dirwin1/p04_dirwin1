//
//  GameViewController.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 9/25/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    var scene: GameScene!
    var level: Level!
    
    func beginGame() {
      shuffle()
    }

    func shuffle() {
      let newBlocks = level.shuffle()
      scene.addSprites(for: newBlocks)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            super.viewDidLoad()
            
            // Configure the view
            let skView = view as! SKView
            skView.isMultipleTouchEnabled = false
            
            level = Level()
            
            // Create and configure the scene.
            scene = GameScene(size: skView.bounds.size)
            scene.scaleMode = .aspectFill
            scene.level = level
            scene.swipeHandler = handleSwipe
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            beginGame()
            
            // Present the scene.
            skView.presentScene(scene)
        }
    }
    
    func handleSwipe(_ swap: Swap) {
      view.isUserInteractionEnabled = false

      level.performSwap(swap)
      scene.animate(swap) {
            self.view.isUserInteractionEnabled = true
      }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
