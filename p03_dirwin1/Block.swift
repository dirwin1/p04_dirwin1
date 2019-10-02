//
//  Block.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/2/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation

enum BlockType : Int{
    case unknown = 0, fire, water, grass, electric, spooky
}

class Block : Hashable {
    var row : Int
    var column : Int
    var blockType : BlockType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(row)
        hasher.combine(column)
    }
    
    static func ==(lhs: Block, rhs: Block) -> Bool {
      return lhs.column == rhs.column && lhs.row == rhs.row
      
    }
    
    init(column: Int, row: Int, blockType: BlockType) {
      self.column = column
      self.row = row
      self.blockType = blockType
    }
}
