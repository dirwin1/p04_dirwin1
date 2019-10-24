//
//  Block.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/2/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation
import SpriteKit

enum BlockType : Int{
    case unknown = 0, fire, water, grass, electric, spooky
    
    var spriteName: String {
      let spriteNames = [
        "fire",
        "water",
        "grass",
        "electric",
        "spooky"]

      return spriteNames[rawValue - 1]
    }

    var highlightedSpriteName: String {
      return spriteName + "-Highlighted"
    }
    
    static func random() -> BlockType {
      return BlockType(rawValue: Int(arc4random_uniform(5)) + 1)!
    }
}

class Block : CustomStringConvertible, Hashable {
    var row : Int
    var column : Int
    var blockType : BlockType
    var sprite: SKSpriteNode?
    var origTexture: SKTexture
    var highLightTexture: SKTexture
    var shockTexture: SKTexture
    var fallFrames: [SKTexture] = []
    var flashFrames: [SKTexture] = []
    var falling: Bool = false
    var chainCount: Int = 1
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
    
    var description: String {
      return "type:\(blockType) square:(\(column),\(row))"
    }
    
    static func ==(lhs: Block, rhs: Block) -> Bool {
      return lhs.column == rhs.column && lhs.row == rhs.row
    }
    
    init(column: Int, row: Int, blockType: BlockType) {
        self.column = column
        self.row = row
        self.blockType = blockType
        
        //get animation files
        //let spriteAtlas = SKTextureAtlas(named: "Sprites")
        origTexture = SKTexture(imageNamed: blockType.spriteName)
        origTexture.filteringMode = .nearest
        shockTexture = SKTexture(imageNamed: "\(blockType.spriteName)shock")
        shockTexture.filteringMode = .nearest
        highLightTexture = SKTexture(imageNamed: "\(blockType.spriteName)-Highlighted")
        highLightTexture.filteringMode = .nearest
        
        let numImages = 4
        for i in 1...numImages {
            let spriteName = "\(blockType.spriteName)fall\(i)"
            let tex = SKTexture(imageNamed: spriteName)
            tex.filteringMode = .nearest
            fallFrames.append(tex)
        }
        
        //flash animation
        let flashTexture = SKTexture(imageNamed: "\(blockType.spriteName)flash")
        flashTexture.filteringMode = .nearest
        for _ in 1...4{
            flashFrames.append(flashTexture)
            flashFrames.append(origTexture)
        }
    }
}
