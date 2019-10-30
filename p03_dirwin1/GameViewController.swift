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
    var profile: Profile!
    var scene: GameScene!
    var level: Level!
    var height: Int = 0
    let maxHeight: Int = 1000
    var speed: Int = 5
    let boostSpeed: Int = 80
    var savedSpeed: Int = 5
    
    func beginGame() {
        shuffle()
        scene.animateStartCountdown()
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
            
            view.showsFPS = true
            view.showsNodeCount = true
            
            profile = Profile()
            
            // Present the scene.
            goToMenu()
        }
    }
    
    func initializeGameScene(){
        // Create and configure the scene.
        scene.scaleMode = .aspectFill
        scene.level = level
        scene.controller = self
        scene.swipeHandler = handleSwipe
        scene.fallHandler = handleFall
        scene.moveHandler = handleMove
        scene.speedUpHandler = handleSpeedUp
        scene.restartHandler = restartGame
        scene.menuHandler = goToMenu
        
        height = 0
        speed = 5
        savedSpeed = 5
    }
    
    func restartGame(){
        if let view = self.view as! SKView? {
            level = Level()
            
            scene = GameScene(size: view.bounds.size)
            initializeGameScene()
            
            let transition = SKTransition.fade(withDuration: 1.0) // create type of transition (you can check in documentation for more transtions)
            
            beginGame()
            
            view.presentScene(scene, transition: transition)
        }
    }
    
    func goToMenu(){
        if let view = self.view as! SKView? {
            let menuScene = MenuScene(size: view.bounds.size)
            menuScene.playHandler = restartGame
            menuScene.statsHandler = goToStats
            
            let transition = SKTransition.fade(withDuration: 1.0)
            view.presentScene(menuScene, transition: transition)
        }
    }
    
    func goToStats(){
        if let view = self.view as! SKView? {
            let statsScene = StatsScene(size: view.bounds.size)
            statsScene.backHandler = goToMenu
            statsScene.profile = profile
            
            let transition = SKTransition.fade(withDuration: 1.0)
            view.presentScene(statsScene, transition: transition)
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
            let match = self.level.performSwap(from: from, to: to)
            //unlock the positions that we swapped with
            self.level.unlockPosition(pos: from)
            self.level.unlockPosition(pos: to)
            
            //now handle matches
            self.handleMatches(match: match)
        }
    }
    
    func handleFall(){
        let sets = level.fall()
        let fallen = sets.0
        let landed = sets.1
        let match = sets.2
        scene.animateFallenBlocks(for: fallen, completion: {})
        scene.animateLanding(for: landed)
        handleMatches(match: match)
        
        //check for chain end
        level.endChain()
    }
    
    private func handleMatches(match: Set<Block>){
        //update profile
        profile.blocksBroken += match.count
        profile.setHighestCombo(combo: match.count)
        
        //lock all match positions
        var sortedMatches: [Block] = []
        var chainCount: Int = 1
        var isChain: Bool = false
        var matchPositions: Set<Point> = []
        for block in match{
            if block.inChain == true{
                profile.setHighestChain(chain: level.chainCount)
                chainCount = level.chainCount
                isChain = true
            }
            let col = block.column
            let row = block.row
            let pos = Point(x: col, y: row)
            matchPositions.insert(pos)
            sortedMatches.append(block)
        }
        
        if isChain{
            level.chainCount += 1
            //set all of the blocks in the match to a chain so we don't end the chain too early
            for block in match{
                if block.inChain == false{
                    block.inChain = true
                    level.chainBlocksCount += 1
                }
            }
        }
        
        //sort the blocks by position
        sortedMatches.sort(by: {
            if $0.row == $1.row{
                return $0.column < $1.column
            }
            else {
                return $0.row > $1.row
            }
        })
        
        self.level.lockPosition(positions: matchPositions)
        
        //animate match
        self.scene.animateMatchedBlocks(for: sortedMatches, chain: chainCount){
            //remove matches
            self.level.removeBlocks(in: match)
            //unlock the match position
            self.level.unlockPosition(positions: matchPositions)
        }
    }
    
    private func handleMove(){
        if level.lockedPositions.isEmpty && level.fallingBlocksCount == 0{
            height = height + speed
            if(height >= maxHeight){
                //need to add a new row
                let moved = level.addRow()
                
                if moved.3 == false{
                    //oh no, we lost :(
                    height = maxHeight - 1
                    handleLoss()
                }
                else{
                    scene.addSprites(for: moved.1)
                    scene.animateFallenBlocks(for: moved.0, completion:{})
                    handleMatches(match: moved.2)
                }
            }
            //check for bouncey boyes
            let bounced = level.checkForBouncers()
            scene.stopBouncing(blocks: bounced.0)
            scene.startBouncing(blocks: bounced.1)
            
            height = height % maxHeight
            scene.moveBoard(height: height)
        }
    }
    
    private func handleLoss(){
        speed = 0
        profile.setHighScore(score: scene.scoreVal)
        scene.animateLoss()
    }
    
    private func handleSpeedUp(){
        speed += 1
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
    
    func startBoost(){
        savedSpeed = speed
        speed = boostSpeed
    }
    
    func endBoost(){
        speed = savedSpeed
    }
}
