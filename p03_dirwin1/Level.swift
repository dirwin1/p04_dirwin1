//
//  Level.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/4/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation

let numColumns = 6
let numRows = 12

class Level {
    private var blocks = [[Block?]](repeating: [Block?](repeating: nil, count: numColumns), count: numRows)
    
    func block(atColumn column: Int, row: Int) -> Block? {
      precondition(column >= 0 && column < numColumns)
      precondition(row >= 0 && row < numRows)
      return blocks[column][row]
    }
    
    func shuffle() -> Set<Block> {
      return initializeBlocks()
    }
    
    private func initializeBlocks() -> Set<Block> {
      var set: Set<Block> = []

      // 1
      for row in 0..<numRows {
        for column in 0..<numColumns {

          // 2
          let blockType = BlockType.random()

          // 3
          let block = Block(column: column, row: row, blockType: blockType)
          blocks[column][row] = block

          // 4
          set.insert(block)
        }
      }
      return set
    }
}
