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
            let skView = view
            skView.isMultipleTouchEnabled = false
            
            level = Level()
            
            // Create and configure the scene.
            scene = GameScene(size: skView.bounds.size)
            scene.scaleMode = .aspectFill
            scene.level = level
            scene.swipeHandler = handleSwipe
            scene.fallHandler = handleFall
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            beginGame()
            
            // Present the scene.
            skView.presentScene(scene)
        }
    }
    
    func handleSwipe(from: Point, to: Point) {
        //first make sure we can swap these blocks
        if(level.isLocked(pos: from) || level.isLocked(pos: to)){
            return
        }
        
        //if not locked, then lock them so we can swap
        level.lockPosition(pos: from)
        level.lockPosition(pos: to)
        
        //animate and wait for the animation to finish to update the level
        scene.animateSwap(from: from, to: to) {
            //update the data
            self.level.performSwap(from: from, to: to)
            //unlock the positions that we swapped with
            self.level.unlockPosition(pos: from)
            self.level.unlockPosition(pos: to)
            
            //now check for matches
            let match = self.level.removeMatches(from: from, to: to)
            self.handleMatches(match: match)
        }
    }
    
    func handleFall(){
        let newFallers = level.startFall()
        fall(falling: newFallers)
    }
    
    func fall(falling: Set<Block>){
        scene.animateFallenBlocks(for: falling, completion: {
            let sets = self.level.completefall(falling: falling)
            let fallen = sets.0
            let landed = sets.1
            let match = sets.2
            self.scene.animateLanding(for: landed)
            self.handleMatches(match: match)
            self.fall(falling: fallen)
        })
    }
    
    private func handleMatches(match: Set<Block>){
        //lock all match positions
        var matchPositions: Set<Point> = []
        for block in match{
            let col = block.column
            let row = block.row
            let pos = Point(x: col, y: row)
            matchPositions.insert(pos)
        }
        self.level.lockPosition(positions: matchPositions)
        
        //animate match
        self.scene.animateMatchedBlocks(for: match){
            //remove matches
            self.level.removeBlocks(in: match)
            //unlock the match position
            self.level.unlockPosition(positions: matchPositions)
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
