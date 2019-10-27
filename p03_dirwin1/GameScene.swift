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
    private var swipeFromBlock: Block?
    var swipeHandler: ((Point, Point) -> Void)?
    var fallHandler: (() -> Void)?
    var moveHandler: (() -> Void)?
    var speedUpHandler: (() -> Void)?
    private var shineTextures : [SKTexture]  = []
    private var boostTextures : [SKTexture] = []
    private var selectionSprite = SKSpriteNode()
    private var speedUpPeriod: Int = 750 //speed up every
    private var speedUpCounter: Int = 0
    private var running: Bool = true
    var timer : SKLabelNode = SKLabelNode()
    
    //Immediately after leveTimerValue variable is set, update label's text
    var timerValue: Int = 0 {
        didSet {
            let min = timerValue / 60
            var sec: String
            if timerValue % 60 < 10{
                sec = "0\(timerValue%60)"
            }
            else{
                sec = "\(timerValue%60)"
            }
            timer.text = "\(min):\(sec)"
        }
    }
    
    var level: Level!
    var controller: GameViewController!

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
        
        tileWidth = min(((0.85 * displayWidth) / 6), (0.85 * displayHeight / 12))
        tileHeight = tileWidth
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //setup background and border
        let backgroundTexture = SKTexture(imageNamed: "Background1")
        let background = SKSpriteNode(texture: backgroundTexture)
        background.color = UIColor.black
        background.colorBlendFactor = 0.5
        background.size = size
        let borderTexture = SKTexture(imageNamed: "Border")
        borderTexture.filteringMode = .nearest
        let border = SKSpriteNode(texture: borderTexture)
        border.size = CGSize(width: 10 * tileWidth, height: 16 * tileHeight)
        
        addChild(background)
        addChild(gameLayer)
        addChild(border)
        
        //setup timer
        timer.fontColor = UIColor.white
        timer.fontSize = 40
        timer.position = CGPoint(x: 0, y: (displayHeight / 2) - tileHeight * 1.25)
        timer.text = "\(timerValue)"
        border.addChild(timer)
        
        let wait = SKAction.wait(forDuration: 1) //change countdown speed here
        let block = SKAction.run({
            self.timerValue += 1
        })
        let sequence = SKAction.sequence([wait,block])
        run(SKAction.repeatForever(sequence), withKey: "countdown")
        
        //setup boost button
        for i in 1...2{
            let tex = SKTexture(imageNamed: "boostbutton\(i)")
            tex.filteringMode = .nearest
            boostTextures.append(tex)
        }
        let boostButton = FTButtonNode(normalTexture: boostTextures[0], selectedTexture: boostTextures[1], disabledTexture: boostTextures[1])
        boostButton.setButtonAction(target: self, triggerEvent: .TouchDown, action: #selector(GameScene.startBoost))
        boostButton.setButtonAction(target: self, triggerEvent: .TouchUp, action: #selector(GameScene.endBoost))
        
        boostButton.size = CGSize(width: 3 * tileWidth, height: tileHeight)
        
        border.addChild(boostButton)
        boostButton.position = CGPoint(x: 0, y: (-displayHeight / 2) + tileHeight * 0.75)
        
        //cache effects
        for i in 1...11{
            let shinetex = SKTexture(imageNamed: "shine\(i)")
            shinetex.filteringMode = .nearest
            shineTextures.append(shinetex)
        }

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
            if block.row == -1{
                sprite.color = UIColor.black
                sprite.colorBlendFactor = 0.7
            }
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
    
    func showComboIndicator(position: CGPoint, size: Int, isChain: Bool){
        if size < 4 || size > 9{
            return
        }
        //create the combo sprite
        let texture = SKTexture(imageNamed: "combo-\(size)")
        texture.filteringMode = .nearest
        
        let sprite = SKSpriteNode(texture: texture)
        
        var offset: CGFloat = 0
        if isChain {
            offset = tileHeight
        }
        sprite.position = CGPoint(x: position.x, y: position.y - offset)
        sprite.size = CGSize(width: tileWidth, height: tileHeight)
        sprite.zPosition = 250
        
        blocksLayer.addChild(sprite)
        
        //create the shine sprite
        let shineSprite = SKSpriteNode(texture: shineTextures[0])
        shineSprite.size = CGSize(width: tileWidth, height: tileHeight)
        sprite.addChild(shineSprite)
        
        //animate the combo sprite
        let duration: Double = 1
        let move = SKAction.move(to: CGPoint(x: position.x, y: position.y - offset + tileHeight / 1.25), duration: duration)
        move.timingMode = .easeOut
        sprite.run(SKAction.sequence([move, SKAction.removeFromParent()]))
        shineSprite.run(SKAction.animate(with: shineTextures, timePerFrame: 0.09))
    }
    
    func showChainIndicator(position: CGPoint, size: Int){
        if size > 9 {
            return
        }
        //create the chain sprite
        let texture = SKTexture(imageNamed: "chain-\(size)")
        texture.filteringMode = .nearest
        
        let sprite = SKSpriteNode(texture: texture)
        sprite.position = position
        sprite.size = CGSize(width: tileWidth, height: tileHeight)
        sprite.zPosition = 250
        
        blocksLayer.addChild(sprite)
        
        //create the shine sprite
        let shineSprite = SKSpriteNode(texture: shineTextures[0])
        shineSprite.size = CGSize(width: tileWidth, height: tileHeight)
        sprite.addChild(shineSprite)
        
        //animate the chain sprite
        let duration: Double = 1
        let move = SKAction.move(to: CGPoint(x: position.x, y: position.y + tileHeight / 1.25), duration: duration)
        move.timingMode = .easeOut
        sprite.run(SKAction.sequence([move, SKAction.removeFromParent()]))
        shineSprite.run(SKAction.animate(with: shineTextures, timePerFrame: 0.09))
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
                swipeFromBlock = block
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard swipeFromBlock != nil else { return }

        guard let touch = touches.first else { return }
        let location = touch.location(in: blocksLayer)

        let (success, column, _) = convertPoint(location)
        if success {
            var horizontalDelta = 0
            if column < swipeFromBlock!.column {          // swipe left
                horizontalDelta = -1
            } else if column > swipeFromBlock!.column {   // swipe right
                horizontalDelta = 1
            }

            if horizontalDelta != 0 {
                trySwap(horizontalDelta: horizontalDelta)
                hideSelectionIndicator()
                //set block back to nil to wait for another swipe
                swipeFromBlock = nil
            }
        }
    }
    
    func moveBoard(height: Int){
        let h = CGFloat(height)/1000.0
        let xPos = -tileWidth * CGFloat(numColumns) / 2
        let yPos = -tileHeight * ((CGFloat(numRows) / 2) - h)
        blocksLayer.position = CGPoint(
        x: xPos,
        y: yPos)
    }
    
    private func trySwap(horizontalDelta: Int) {
        let toColumn = swipeFromBlock!.column + horizontalDelta
        guard toColumn >= 0 && toColumn < numColumns else { return }

        if let handler = swipeHandler{
            handler(Point(x: swipeFromBlock!.column, y: swipeFromBlock!.row), Point(x: toColumn, y: swipeFromBlock!.row))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromBlock != nil {
            hideSelectionIndicator()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
      touchesEnded(touches, with: event)
    }
    
    func animateSwap(from: Point, to: Point, completion: @escaping () -> Void) {
        let posA = pointFor(column: from.x, row: from.y)
        let posB = pointFor(column: to.x, row: to.y)
        let blockA = level.block(atColumn: from.x, row: from.y)
        let blockB = level.block(atColumn: to.x, row: to.y)
        
        let duration: TimeInterval = 0.05
        
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
        
        var waitDur = 2 * duration
        if level.block(atColumn: to.x, row: to.y - 1) == nil{
            waitDur += 0.05
        }
        
        run(SKAction.wait(forDuration: waitDur), completion: completion)
        //run(swapSound)
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        if running{
            fallHandler!()
            if(speedUpCounter == 0){
                speedUpHandler!()
            }
            moveHandler!()
            
            speedUpCounter = (speedUpCounter + 1) % speedUpPeriod
        }
    }
    
    func animateMatchedBlocks(for blocks: [Block], chain: Int, completion: @escaping () -> Void) {
        //show indicators
        if blocks.count > 0 {
            let pos = pointFor(column: blocks.first!.column, row: blocks.first!.row)
            var isChain: Bool = false
            if(chain > 1){
                isChain = true
                showChainIndicator(position: pos, size: chain)
            }
            showComboIndicator(position: pos, size: blocks.count, isChain: isChain)
        }
        
        //animate the blocks
        var waitTime: Double = 0.15
        
        for block in blocks {
            if let sprite = block.sprite {
                if sprite.action(forKey: "removing") == nil {
                    sprite.removeAllActions()
                    sprite.zPosition = 100
                    
                    let flash = SKAction.animate(with: block.flashFrames, timePerFrame: 0.04, resize: false, restore: true)
                    let shock = SKAction.run({
                        sprite.texture = block.shockTexture
                    })
                    let wait = SKAction.wait(forDuration: waitTime)
                    let grow = SKAction.scale(to: 1.5, duration: 0.1)
                    grow.timingMode = .easeIn
                    let die = SKAction.removeFromParent()
                    
                    sprite.run(SKAction.sequence([flash, flash, shock, wait, grow, die]))
                    
                    waitTime += 0.15
                }
            }
        }

        run(SKAction.wait(forDuration: 1 + waitTime - 0.2), completion: completion)
    }
    
    func animateFallenBlocks(for blocks: Set<Block>, completion: @escaping () -> Void){
        for block in blocks{
            if let sprite = block.sprite{
                sprite.position = pointFor(column: block.column, row: block.row)
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
    
    func animateLoss(){
        running = false
        
        //shake the screen
        shake(times: 30, ampX: 30, ampY: 30)
        
        //kill all of the blocks
    }
    
    func shake(times: Int, ampX: Int, ampY: Int) {
        let initialPoint: CGPoint = gameLayer.position;
        var randomActions: [SKAction] = []
        for _ in 0..<times {
            let randX = Int(initialPoint.x) + (Int(arc4random()) % ampX) - ampX/2
            let randY = Int(initialPoint.y) + (Int(arc4random()) % ampY) - ampY/2
            let action = SKAction.move(to: CGPoint(x: randX, y: randY), duration: 0.01)
            randomActions.append(action)
        }
        
        randomActions.append(SKAction.move(to: initialPoint, duration: 0.01))

        gameLayer.run(SKAction.sequence(randomActions))
    }
    
    @objc func startBoost(){
        print("Boost Started")
        controller.startBoost()
    }
    
    @objc func endBoost(){
        print("Boost Ended")
        controller.endBoost()
    }
    
    func startBouncing(blocks: Set<Block>){
        for block in blocks{
            if let sprite = block.sprite{
                if sprite.action(forKey: "bouncing") == nil{
                    sprite.run(SKAction.repeatForever(SKAction.animate(with: block.fallFrames, timePerFrame: 0.08)), withKey: "bouncing")
                }
            }
        }
    }
    
    func stopBouncing(blocks: Set<Block>){
        for block in blocks{
            if let sprite = block.sprite{
                sprite.removeAction(forKey: "bouncing")
                sprite.texture = block.origTexture
            }
        }
    }
}
