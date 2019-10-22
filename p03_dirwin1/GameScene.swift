//
//  GameScene.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/4/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//
import SpriteKit
import GameplayKit

class GameScene: SKScene {
    private var swipeFromColumn: Int?
    private var swipeFromRow: Int?
    var swipeHandler: ((Point, Point) -> Void)?
    var fallHandler: (() -> Void)?
    var moveHandler: (() -> Void)?
    private var selectionSprite = SKSpriteNode()
    private var fallCounter: Int = 0
    
    var level: Level!

    var tileWidth: CGFloat = 64.0
    var tileHeight: CGFloat = 64.0

    let gameLayer = SKNode()
    let blocksLayer = SKNode()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder) is not used in this app")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        //figure out block size
        let displaySize: CGRect = UIScreen.main.bounds
        let displayWidth = displaySize.width
        let displayHeight = displaySize.height
        
        tileWidth = min(((0.95 * displayWidth) / 6), (0.95 * displayHeight / 12))
        tileHeight = tileWidth
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        let background = SKSpriteNode(imageNamed: "Background")
        background.size = size
        //addChild(background)
        addChild(gameLayer)

        let layerPosition = CGPoint(
            x: -tileWidth * CGFloat(numColumns) / 2,
            y: -tileHeight * CGFloat(numRows) / 2)

        blocksLayer.position = layerPosition
        gameLayer.addChild(blocksLayer)
    }
    
    
    func addSprites(for blocks: Set<Block>) {
        for block in blocks {
            let sprite = SKSpriteNode(imageNamed: block.blockType.spriteName)
            sprite.size = CGSize(width: tileWidth, height: tileHeight)
            sprite.position = pointFor(column: block.column, row: block.row)
            blocksLayer.addChild(sprite)
            block.sprite = sprite
        }
    }
    
    func showSelectionIndicator(of block: Block) {
        if selectionSprite.parent != nil {
            selectionSprite.removeFromParent()
        }

        if let sprite = block.sprite {
            let texture = SKTexture(imageNamed: block.blockType.highlightedSpriteName)
            selectionSprite.size = CGSize(width: tileWidth, height: tileHeight)
            selectionSprite.run(SKAction.setTexture(texture))

            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()]))
    }

    private func pointFor(column: Int, row: Int) -> CGPoint {
      return CGPoint(
        x: CGFloat(column) * tileWidth + tileWidth / 2,
        y: CGFloat(row) * tileHeight + tileHeight / 2)
    }
    
    private func convertPoint(_ point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(numColumns) * tileWidth &&
            point.y >= 0 && point.y < CGFloat(numRows) * tileHeight {
            return (true, Int(point.x / tileWidth), Int(point.y / tileHeight))
        }
        else {
            return (false, 0, 0)  // invalid location
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: blocksLayer)

        let (success, column, row) = convertPoint(location)
        if success {
            if let block = level.block(atColumn: column, row: row) {
                showSelectionIndicator(of: block)
                swipeFromColumn = column
                swipeFromRow = row
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromColumn != nil else { return }

        guard let touch = touches.first else { return }
        let location = touch.location(in: blocksLayer)

        let (success, column, _) = convertPoint(location)
        if success {
            var horizontalDelta = 0
            if column < swipeFromColumn! {          // swipe left
                horizontalDelta = -1
            } else if column > swipeFromColumn! {   // swipe right
                horizontalDelta = 1
            }

            if horizontalDelta != 0 {
                trySwap(horizontalDelta: horizontalDelta)
                hideSelectionIndicator()
                // 5
                swipeFromColumn = nil
            }
        }
    }
    
    func moveBoard(height: Int){
        let h = CGFloat(height)/100.0
        let xPos = -tileWidth * CGFloat(numColumns) / 2
        let yPos = -tileHeight * ((CGFloat(numRows) / 2) - h)
        blocksLayer.position = CGPoint(
        x: xPos,
        y: yPos)
    }
    
    private func trySwap(horizontalDelta: Int) {
        let toColumn = swipeFromColumn! + horizontalDelta
        guard toColumn >= 0 && toColumn < numColumns else { return }

        if let handler = swipeHandler{
            handler(Point(x: swipeFromColumn!, y: swipeFromRow!), Point(x: toColumn, y: swipeFromRow!))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        
        swipeFromColumn = nil
        swipeFromRow = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
      touchesEnded(touches, with: event)
    }
    
    func animateSwap(from: Point, to: Point, completion: @escaping () -> Void) {
        let posA = pointFor(column: from.x, row: from.y)
        let posB = pointFor(column: to.x, row: to.y)
        let blockA = level.block(atColumn: from.x, row: from.y)
        let blockB = level.block(atColumn: to.x, row: to.y)
        
        let duration: TimeInterval = 0.075
        
        if blockA != nil{
            let spriteA = blockA?.sprite!
            spriteA?.zPosition = 100
            
            let moveA = SKAction.move(to: posB, duration: duration)
            moveA.timingMode = .easeOut
            spriteA?.run(moveA)
        }
        
        if blockB != nil{
            let spriteB = blockB?.sprite!
            spriteB?.zPosition = 90
            
            let moveB = SKAction.move(to: posA, duration: duration)
            moveB.timingMode = .easeOut
            spriteB?.run(moveB)
        }
        run(SKAction.wait(forDuration: 0.15), completion: completion)
        //run(swapSound)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        //if fallCounter == 1 {
            fallHandler!()
            moveHandler!()
        //}
        //fallCounter = (fallCounter + 1) % 2
    }
    
    func animateMatchedBlocks(for blocks: Set<Block>, completion: @escaping () -> Void) {
        for block in blocks {
            if let sprite = block.sprite {
                if sprite.action(forKey: "removing") == nil {
                    //let scaleAction = SKAction.scale(to: 0.1, duration: 1)
                    //scaleAction.timingMode = .easeOut
                    //sprite.run(SKAction.sequence([scaleAction, SKAction.removeFromParent()]), withKey: "removing")
                    sprite.removeAllActions()
                    
                    let flash = SKAction.animate(with: block.flashFrames, timePerFrame: 0.1, resize: false, restore: true)
                    let shock = SKAction.run({
                        sprite.texture = block.shockTexture
                    })
                    
                    sprite.run(SKAction.sequence([flash, shock]))
                    
                   // sprite.run(SKAction.animate(with: block.flashFrames, timePerFrame: 0.1, resize: false, restore: true), withKey: "removing")
                }
            }
        }
        var waitTime: Double = 0.15
        for block in blocks{
            if let sprite = block.sprite{
                let wait = SKAction.wait(forDuration: 1 + waitTime)
                let die = SKAction.removeFromParent()
                sprite.run(SKAction.sequence([wait, die]))
                waitTime += 0.15
            }
        }
        run(SKAction.wait(forDuration: 1 + waitTime), completion: completion)
    }
    
    func animateFallenBlocks(for blocks: Set<Block>, completion: @escaping () -> Void){
        for block in blocks{
            if let sprite = block.sprite{
                sprite.position = pointFor(column: block.column, row: block.row)
                //block.falling = true
                //let pos = pointFor(column: block.column, row: block.row)
                //let move = SKAction.move(to: pos, duration: 0.01)
                //let flag = SKAction.run({
                    //block.falling = false
                //})
                //move.timingMode = .easeOut
                //sprite.run(SKAction.sequence([move, flag]), completion: completion)
                //sprite.run(move, completion: completion)
            }
        }
    }
    
    func animateLanding(for blocks: Set<Block>) {
        for block in blocks{
            if let sprite = block.sprite{
                sprite.removeAction(forKey: "land")
                sprite.texture = block.origTexture
                sprite.run(SKAction.animate(with: block.fallFrames, timePerFrame: 0.05, resize: false,
                                            restore: true), withKey: "land")
            }
        }
    }
}
