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
    var pauseHandler: (() -> Void)?
    var unPauseHandler: (() -> Void)?
    var restartHandler: (() -> Void)?
    var menuHandler: (() -> Void)?
    private var shineTextures : [SKTexture]  = []
    private var boostTextures : [SKTexture] = []
    private var pauseButtonTextures : [SKTexture] = []
    private var screamTextures : [SKTexture] = []
    private var particleTexture: SKTexture = SKTexture(imageNamed: "particle1")
    private var selectionSprite = SKSpriteNode()
    private var speedUpPeriod: Int = 750 //speed up every
    private var speedUpCounter: Int = 0
    private var running: Bool = false
    private var gamePaused: Bool = false
    var timer : SKLabelNode = SKLabelNode(fontNamed: "7:12 Serif Regular")
    var score : SKLabelNode = SKLabelNode(fontNamed: "7:12 Serif Regular")
    var pausedLabel: SKLabelNode? = nil
    var countDownLabel: SKLabelNode? = nil
    var speedLabel: SKLabelNode = SKLabelNode(fontNamed: "7:12 Serif Regular")
    var highScoreLabel: SKLabelNode = SKLabelNode(fontNamed: "7:12 Serif Regular")
    var gameOverLabel: SKLabelNode? = nil
    var retryButton: FTButtonNode? = nil
    var menuButton: FTButtonNode? = nil
    var continueButton: FTButtonNode? = nil
    var dimmer: SKSpriteNode? = nil
    
    let notificationCenter = NotificationCenter.default
    @objc func appMovedCameBack() {
        if running == true{
            animatePause()
        }
    }
    
    //Immediately after leveTimerValue variable is set, update label's text
    var timerValue: Int = 0 {
        didSet {
            let min: String
            var sec: String
            if timerValue % 60 < 10{
                sec = "0\(timerValue%60)"
            }
            else{
                sec = "\(timerValue%60)"
            }
            
            if timerValue / 60 < 10 {
                min = "0\(timerValue / 60)"
            }
            else{
                min = "\(timerValue / 60)"
            }
            timer.text = "\(min):\(sec)"
        }
    }
    
    var scoreVal: Int = 0 {
        didSet{
            score.text = "\(scoreVal)"
        }
    }
    
    var speedVal: Int = 0 {
        didSet{
            speedLabel.text = "\(speedVal)"
        }
    }
    
    var highScoreVal: Int = 0{
        didSet{
            highScoreLabel.text = "Hi: \(highScoreVal)"
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
        //let displayWidth = displaySize.width
        let displayHeight = displaySize.height
        let displayWidth = displaySize.width
        
        //tileWidth = min(((0.8 * displayWidth) / 6), (0.8 * displayHeight / 12))
        tileWidth = (0.77 * displayHeight / 12)
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
        timer.position = CGPoint(x: -tileWidth * 2.15, y: (displayHeight / 2) - tileHeight * 1.18)
        timer.text = "0:00"
        border.addChild(timer)
        
        let wait = SKAction.wait(forDuration: 1) //change countdown speed here
        let block = SKAction.run({
            if self.running{
                self.timerValue += 1
            }
        })
        let sequence = SKAction.sequence([wait,block])
        run(SKAction.repeatForever(sequence), withKey: "countdown")
        
        //setup score label
        score.fontColor = UIColor.white
        score.horizontalAlignmentMode = .right
        score.fontSize = 40
        score.position = CGPoint(x: tileWidth * 3, y: (displayHeight / 2) - tileHeight * 1.18)
        score.text = "0"
        border.addChild(score)
        
        //setup speed label
        speedLabel.fontColor = UIColor.white
        speedLabel.fontSize = 40
        speedLabel.position = CGPoint(x: 0, y: (displayHeight / 2) - tileHeight * 1.18)
        speedLabel.text = "5"
        border.addChild(speedLabel)
        
        //setup highscore label
        highScoreLabel.fontColor = UIColor.black
        highScoreLabel.alpha = 0.35
        highScoreLabel.fontSize = 36
        highScoreLabel.position = CGPoint(x: 0, y: (displayHeight / 2) - tileHeight * 2.25)
        highScoreLabel.text = "hi 100250"
        background.addChild(highScoreLabel)
        
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
        
        //setup pause button
        for i in 1...2{
            let tex = SKTexture(imageNamed: "pausebutton\(i)")
            tex.filteringMode = .nearest
            pauseButtonTextures.append(tex)
        }
        
        let pauseButton = FTButtonNode(normalTexture: pauseButtonTextures[0], selectedTexture: pauseButtonTextures[1], disabledTexture: pauseButtonTextures[1])
        pauseButton.size = CGSize(width: tileWidth, height: tileHeight)
        border.addChild(pauseButton)
        pauseButton.position = CGPoint(x: (-displayWidth / 2) + tileWidth, y: (-displayHeight / 2) + tileHeight * 0.75)
        pauseButton.setButtonAction(target: self, triggerEvent: .TouchUpInside, action: #selector(animatePause))
        
        //create menu buttons
        createMenuButton(button: &menuButton, text: "menu", color: UIColor.red, selector: #selector(goToMenu))
        createMenuButton(button: &retryButton, text: "retry", color: UIColor.blue, selector: #selector(restart))
        createMenuButton(button: &continueButton, text: "continue", color: UIColor.green, selector: #selector(animatePause))
        
        
        //cache effects
        for i in 1...11{
            let shinetex = SKTexture(imageNamed: "shine\(i)")
            shinetex.filteringMode = .nearest
            shineTextures.append(shinetex)
        }
        
        for i in 1...6{
            let screamtex = SKTexture(imageNamed: "Scream\(i)")
            screamtex.filteringMode = .nearest
            screamTextures.append(screamtex)
        }
        
        particleTexture.filteringMode = .nearest

        let layerPosition = CGPoint(
            x: -tileWidth * CGFloat(numColumns) / 2,
            y: -tileHeight * CGFloat(numRows) / 2)

        blocksLayer.position = layerPosition
        gameLayer.addChild(blocksLayer)
        
        //Pause when the app goes out of scope
        notificationCenter.addObserver(self, selector: #selector(appMovedCameBack), name: UIApplication.didBecomeActiveNotification, object: nil)
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
        if running {
            let toColumn = swipeFromBlock!.column + horizontalDelta
            guard toColumn >= 0 && toColumn < numColumns else { return }

            if let handler = swipeHandler{
                handler(Point(x: swipeFromBlock!.column, y: swipeFromBlock!.row), Point(x: toColumn, y: swipeFromBlock!.row))
            }
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
        
        if let blocka = blockA {
            let spriteA = blocka.sprite!
            spriteA.zPosition = 100
            
            let moveA = SKAction.move(to: posB, duration: duration)
            moveA.timingMode = .easeOut
            spriteA.run(moveA)
        }
        
        if let blockb = blockB{
            let spriteB = blockb.sprite!
            spriteB.zPosition = 90
            
            let moveB = SKAction.move(to: posA, duration: duration)
            moveB.timingMode = .easeOut
            spriteB.run(moveB)
        }
        
        let waitDur = 2 * duration
        
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
        let scorePerBlock: Int = blocks.count
        
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
                    
                    //add the screaming face on top
                    let scream = SKSpriteNode(texture: screamTextures[0])
                    scream.size = CGSize(width: tileWidth, height: tileHeight)
                    scream.run(SKAction.repeatForever(SKAction.animate(with: screamTextures, timePerFrame: 0.04)))
                    
                    let flash = SKAction.animate(with: block.flashFrames, timePerFrame: 0.04, resize: false, restore: true)
                    let shock = SKAction.run({
                        sprite.texture = block.highLightTexture
                        sprite.addChild(scream)
                    })
                    let wait = SKAction.wait(forDuration: waitTime)
                    let grow = SKAction.scale(to: 1.5, duration: 0.1)
                    grow.timingMode = .easeIn
                    let die = SKAction.run({
                        self.createPopParticles(position: sprite.position, num: 2 + chain * 2)
                        self.scoreVal += (scorePerBlock * chain)
                    })
                    
                    sprite.run(SKAction.sequence([flash, flash, shock, wait, grow, die, SKAction.removeFromParent()]))

                    
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
        
        var waitToShrink: Double = 1
        //kill all of the blocks
        for row in (0..<numRows).reversed(){
            for col in 0..<numColumns{
                if let block = level.block(atColumn: col, row: row){
                    if let sprite = block.sprite{
                        killSprite(sprite: sprite, waitToShrink: waitToShrink)
                    }
                }
            }
            waitToShrink += 0.075
        }
        
        //don't forget the new row
        for col in 0..<numColumns{
            if let block = level.upComingRow[col] {
                if let sprite = block.sprite{
                    killSprite(sprite: sprite, waitToShrink: waitToShrink)
                }
            }
        }
        
        //now write out loser
        gameOverLabel = SKLabelNode(fontNamed: "7:12 Serif Regular")
        gameOverLabel?.position = CGPoint(x: 0, y: self.tileHeight * 2)
        gameOverLabel?.fontSize = 64
        gameOverLabel?.color = UIColor.white
        gameOverLabel?.alpha = 0
        addChild(gameOverLabel!)
        gameOverLabel!.text = "loser"
        
        let showGameOver = SKAction.run({
            self.gameOverLabel!.run(SKAction.fadeIn(withDuration: 1))
        })
        
        let showButtons = SKAction.run({
            self.showMenuButton(button: &self.retryButton, yPos: 0)
            self.showMenuButton(button: &self.menuButton, yPos: -self.tileHeight * 1.25)
        })
        
        run(SKAction.sequence([SKAction.wait(forDuration: waitToShrink), showGameOver, showButtons]))
    }
    
    func createMenuButton(button: inout FTButtonNode?, text: String, color: UIColor, selector: Selector){
        let jelly1 = SKTexture(imageNamed: "jellybutton1")
        let jelly2 = SKTexture(imageNamed: "jellybutton2")
        jelly1.filteringMode = .nearest
        jelly2.filteringMode = .nearest
        
        //add in menu button
        button = FTButtonNode(normalTexture: jelly1, selectedTexture: jelly2, disabledTexture: jelly2)
        button!.size = CGSize(width: 5 * tileWidth, height: tileHeight)
        button!.color = color
        button!.colorBlendFactor = 0.65
        button!.setButtonLabel(title: NSString(string: text), font: "7:12 Serif Regular", fontSize: 40)
        button!.zPosition = 10000
        
        button!.setButtonAction(target: self, triggerEvent: .TouchUpInside, action: selector)
    }
    
    func showMenuButton(button: inout FTButtonNode?, yPos: CGFloat){
        if let butt = button{
            addChild(butt)
            butt.position = CGPoint(x: 0, y: yPos)
        }
    }
    
    func hideMenuButton(button: inout FTButtonNode?){
        if let butt = button {
            butt.removeFromParent()
        }
    }
    
    func killSprite(sprite: SKSpriteNode, waitToShrink: Double){
        let background = SKSpriteNode(texture: sprite.texture)
        background.color = UIColor.black
        background.colorBlendFactor = 1
        background.alpha = 0
        background.size = sprite.size
        background.anchorPoint = CGPoint(x: 0.5, y: 0)
        background.zPosition = sprite.zPosition + 1

        sprite.addChild(background)
        background.run(SKAction.fadeIn(withDuration: 1))
        
        //add the screaming face on top
        let scream = SKSpriteNode(texture: screamTextures[0])
        scream.size = CGSize(width: tileWidth, height: tileHeight)
        scream.anchorPoint = CGPoint(x: 0.5, y: 0)
        scream.zPosition = sprite.zPosition + 2
        //let tpf : Double = Double(Int(arc4random_uniform(6))) / 10.0
        let tpf: Double = 0.04
        scream.run(SKAction.repeatForever(SKAction.animate(with: screamTextures, timePerFrame: tpf)))
        sprite.addChild(scream)
        
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        sprite.position = CGPoint(x: sprite.position.x, y: sprite.position.y - sprite.size.height / 2)
        
        let wait = SKAction.wait(forDuration: waitToShrink)
        let shrink = SKAction.scale(to: CGSize(width: sprite.size.width, height: 0), duration: 0.075)
        sprite.run(SKAction.sequence([wait, shrink, SKAction.removeFromParent()]))
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
    
    func createPopParticles(position : CGPoint, num: Int){
        for i in 1...num{
            let dist = Double(tileWidth) * 2
            let angle : Double = (2 * Double.pi * (Double(i) / Double(num))) + (0.25 * Double.pi)
            let sprite = SKSpriteNode(texture: particleTexture)
            sprite.size = CGSize(width: tileWidth/2, height: tileHeight/2)
            blocksLayer.addChild(sprite)
            sprite.position = CGPoint(x: position.x + tileWidth/2 * CGFloat(cos(angle)), y: position.y + tileHeight/2 * CGFloat(sin(angle)))
            sprite.zPosition = 1000
            
            let move = SKAction.move(by: CGVector(dx: dist * cos(angle), dy: dist * sin(angle)), duration: 0.5)
            let rotate = SKAction.rotate(byAngle: 720, duration: 0.5)
            let scale = SKAction.scale(to: 0, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.5)
            move.timingMode = .easeOut
            rotate.timingMode = .easeOut
            fade.timingMode = .easeIn
            scale.timingMode = .easeIn
            
            sprite.run(rotate)
            //sprite.run(fade)
            sprite.run(scale)
            sprite.run(SKAction.sequence([move, SKAction.removeFromParent()]))
        }
    }
    
    func animateStartCountdown(){
        //setup timer
        var timeLeft: Int = 3
        
        countDownLabel = SKLabelNode(fontNamed: "7:12 Serif Regular")
        countDownLabel!.fontColor = UIColor.white
        countDownLabel!.fontSize = 72
        countDownLabel!.position = CGPoint(x: 0, y: 0)
        countDownLabel!.text = "\(timeLeft)"
        countDownLabel!.zPosition = 10000
        addChild(countDownLabel!)
        
        let wait = SKAction.wait(forDuration: 1) //change countdown speed here
        let block = SKAction.run({
            timeLeft -= 1
            self.countDownLabel!.text = "\(timeLeft)"
        })
        let start = SKAction.run({
            self.countDownLabel!.removeFromParent()
            self.running = true
        })
        
        countDownLabel!.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([wait, block]), count: 3), start]))
    }
    
    @objc func animatePause(){
        if gamePaused{
            //unpaused
            if let p = pausedLabel{
                p.removeFromParent()
            }
            
            unDimBackground()
            
            pausedLabel = nil
            hideMenuButton(button: &menuButton)
            hideMenuButton(button: &retryButton)
            hideMenuButton(button: &continueButton)
            
            animateStartCountdown()
            gamePaused = false
        }
        else {
            //pause
            running = false
            
            dimBackground()
            if let countDown = countDownLabel {
                countDown.removeAllActions()
                countDown.removeFromParent()
            }
            
            countDownLabel = nil
            
            //create the pause menu
            pausedLabel = SKLabelNode(fontNamed: "7:12 Serif Regular")
            pausedLabel!.fontColor = UIColor.white
            pausedLabel!.fontSize = 64
            pausedLabel!.position = CGPoint(x: 0, y: tileHeight * 2)
            pausedLabel!.text = "paused"
            pausedLabel!.zPosition = 10000
            addChild(pausedLabel!)
            
            showMenuButton(button: &continueButton, yPos: 0)
            showMenuButton(button: &retryButton, yPos: -tileHeight * 1.25)
            showMenuButton(button: &menuButton, yPos: -tileHeight * 2.5)
            
            gamePaused = true
        }
    }
    
    func dimBackground(){
        dimmer = SKSpriteNode(color: UIColor.black, size: self.size)
        dimmer!.alpha = 0.75
        dimmer!.zPosition = 9900
        dimmer!.position = CGPoint(x: 0, y: 0)
        self.addChild(dimmer!)
    }
    
    func unDimBackground(){
        if let dim = dimmer{
            dim.removeFromParent()
        }
    }
    
    @objc func goToMenu(){
        if let handler = menuHandler {
            handler()
        }
    }
    
    @objc func restart(){
        if let handler = restartHandler{
            handler()
        }
    }
}
