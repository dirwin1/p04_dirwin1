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
        return blocks[row][column]
    }
    
    func shuffle() -> Set<Block> {
        return initializeBlocks()
    }
    
    private func initializeBlocks() -> Set<Block> {
        var set: Set<Block> = []

        // 1
        for row in 0..<numRows {
            for column in 0..<numColumns {
                //make sure we don't create any chains to begin with
                var blockType: BlockType
                
                repeat {
                  blockType = BlockType.random()
                } while (column >= 2 &&
                    blocks[row][column - 1]?.blockType == blockType &&
                    blocks[row][column - 2]?.blockType == blockType) ||
                    (row >= 2 &&
                    blocks[row - 1][column]?.blockType == blockType &&
                    blocks[row - 2][column]?.blockType == blockType)
                
                let block = Block(column: column, row: row, blockType: blockType)
                blocks[row][column] = block

                set.insert(block)
            }
      }
      return set
    }
    
    func performSwap(_ swap: Swap) {
        let columnA = swap.blockA.column
        let rowA = swap.blockA.row
        let columnB = swap.blockB.column
        let rowB = swap.blockB.row
        
        blocks[rowA][columnA] = swap.blockB
        swap.blockB.column = columnA
        swap.blockB.row = rowA

        blocks[rowB][columnB] = swap.blockA
        swap.blockA.column = columnB
        swap.blockA.row = rowB
    }
}
