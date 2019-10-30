//
//  StatsScene.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/30/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import SpriteKit
import UIKit

class StatsTableView: UITableView,UITableViewDelegate,UITableViewDataSource {
    var items: [String] = ["Blocks Broken", "Biggest Combo", "Biggest Chain", "Highscore"]
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.delegate = self
        self.dataSource = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        cell.textLabel?.text = self.items[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Section \(section)"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell #\(indexPath.row)!")
    }
    
}
class StatsScene: SKScene {
    
    var tileWidth: CGFloat = 64.0
    var tileHeight: CGFloat = 64.0
    
    var profile: Profile?
    var backHandler: (() -> Void)?
    
    var gameTableView = StatsTableView()
    private var label : SKLabelNode?
    
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
        
        //setup backbutton
        var backButtonTextures : [SKTexture] = []
        for i in 1...2{
            let tex = SKTexture(imageNamed: "backButton\(i)")
            tex.filteringMode = .nearest
            backButtonTextures.append(tex)
        }
        
        let backButton = FTButtonNode(normalTexture: backButtonTextures[0], selectedTexture: backButtonTextures[1], disabledTexture: backButtonTextures[1])
        backButton.size = CGSize(width: tileWidth, height: tileHeight)
        addChild(backButton)
        backButton.position = CGPoint(x: (-displayWidth / 2) + tileWidth, y: (-displayHeight / 2) + tileHeight * 0.75)
        backButton.setButtonAction(target: self, triggerEvent: .TouchUpInside, action: #selector(goBack))
    }
    
    @objc func goBack(){
        if let handler = backHandler{
            gameTableView.removeFromSuperview()
            handler()
        }
    }
    
    override func didMove(to view: SKView) {
        self.label = self.childNode(withName: "//helloLabel") as? SKLabelNode
        if let label = self.label {
            label.alpha = 0.0
            label.run(SKAction.fadeIn(withDuration: 2.0))
        }
        // Table setup
        gameTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        gameTableView.frame=CGRect(x: tileWidth/2, y: tileHeight * 1.4 ,width:tileWidth * 6, height: tileHeight * 12)
        self.scene?.view?.addSubview(gameTableView)
        gameTableView.reloadData()
        
        if let p = profile{
            gameTableView.items[0] = "Blocks Broken: \(p.blocksBroken)"
            gameTableView.items[1] = "Highest Combo: \(p.highestCombo)"
            gameTableView.items[2] = "Highest Chain: \(p.highestChain)"
            gameTableView.items[3] = "Highscore: \(p.highScore)"
        }
    }
}
