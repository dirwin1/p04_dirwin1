//
//  MenuScene.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/30/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import SpriteKit
import GameplayKit

class MenuScene: SKScene{
    
    var playButton: FTButtonNode? = nil
    var statsButton: FTButtonNode? = nil
    var playHandler: (() -> Void)?
    var statsHandler: (() -> Void)?
    
    var tileWidth: CGFloat = 64.0
    var tileHeight: CGFloat = 64.0
    
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

        tileWidth = (0.77 * displayHeight / 12)
        tileHeight = tileWidth
        
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        //setup background
        let backgroundTexture = SKTexture(imageNamed: "Background2")
        backgroundTexture.filteringMode = .nearest
        let background1 = SKSpriteNode(texture: backgroundTexture)
        background1.size = CGSize(width: 10 * tileWidth, height: 16 * tileWidth)
        background1.color = UIColor.black
        background1.colorBlendFactor = 0.1
        
        let background2 = background1.copy() as! SKSpriteNode
        let background3 = background1.copy() as! SKSpriteNode
        let background4 = background1.copy() as! SKSpriteNode
        
        background1.position = CGPoint(x: -5 * tileWidth, y: 8 * tileHeight)
        background2.position = CGPoint(x: 5 * tileWidth, y: 8 * tileHeight)
        background3.position = CGPoint(x: -5 * tileWidth, y: -8 * tileHeight)
        background4.position = CGPoint(x: 5 * tileWidth, y: -8 * tileHeight)
        
        let background = SKSpriteNode()
        background.addChild(background1)
        background.addChild(background2)
        background.addChild(background3)
        background.addChild(background4)
        
        let reposition = SKAction.move(to: CGPoint(x: -5 * tileWidth, y: 8 * tileHeight), duration: 0)
        let move = SKAction.move(to: CGPoint(x: 5 * tileWidth, y: -8 * tileHeight), duration: 7)
        background.run(SKAction.repeatForever(SKAction.sequence([reposition, move])))
        
        addChild(background)
        
        //create title
        let titleTex = SKTexture(imageNamed: "title")
        titleTex.filteringMode = .nearest
        let title = SKSpriteNode(texture: titleTex)
        title.size = CGSize(width: 6 * tileWidth, height: 4 * tileHeight)
        title.position = CGPoint(x: 0, y: 4.5 * tileHeight)
        
        //animate it
        let moveUp = SKAction.moveTo(y: title.position.y + tileHeight / 4, duration: 0.5)
        moveUp.timingMode = .easeInEaseOut
        
        let moveDown = SKAction.moveTo(y: title.position.y - tileHeight / 4, duration: 0.5)
        moveDown.timingMode = .easeInEaseOut
        
        title.run(SKAction.repeatForever(SKAction.sequence([moveUp, moveDown])))
        addChild(title)
        
        //create menu buttons
        createMenuButton(button: &playButton, text: "play", color: UIColor.blue, selector: #selector(startGame))
        createMenuButton(button: &statsButton, text: "stats", color: UIColor.systemPink, selector: #selector(goToStats))
        //createMenuButton(button: &continueButton, text: "continue", color: UIColor.green, selector: #selector(animatePause))
        
        showMenuButton(button: &playButton, yPos: tileHeight)
        showMenuButton(button: &statsButton, yPos: -tileHeight * 0.5)
        
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
    
    @objc func startGame(){
        if let handler = playHandler{
            handler()
        }
    }
    
    @objc func goToStats(){
        if let handler = statsHandler{
            handler()
        }
    }
}
