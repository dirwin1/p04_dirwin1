//
//  Level.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/4/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation
import SpriteKit

let numColumns = 6
let numRows = 12

class Level {
    private var blocks = [[Block?]](repeating: [Block?](repeating: nil, count: numColumns), count: numRows)
    
    func block(atColumn column: Int, row: Int) -> Block? {
        if(column < 0 || column >= numColumns){
            return nil
        }
        if(row < 0 || row >= numRows){
            return nil
        }
        return blocks[row][column]
    }

    func shuffle() -> Set<Block> {
        return initializeBlocks()
    }
    
    func fall() -> (Set<Block>, Set<Block>){
        var movedBoys: Set<Block> = []
        var landedBoyes: Set<Block> = []
        for row in 0..<numRows{
            for col in 0..<numColumns{
                if block(atColumn: col, row: row) == nil && block(atColumn: col, row: row + 1) != nil{
                    //fall down
                    movedBoys.insert(blocks[row+1][col]!)
                    blocks[row][col] = blocks[row+1][col]
                    blocks[row][col]?.column = col
                    blocks[row][col]?.row = row
                    blocks[row+1][col] = nil
                    
                    if(row == 0 || blocks[row-1][col] != nil){
                        landedBoyes = landedBoyes.union(checkForMatch(at: Point(x: col, y: row)))
                    }
                }
            }
        }
        return (movedBoys, landedBoyes)
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
    
    func performSwap(from: Point, to: Point){
        let blockA : Block? = blocks[from.y][from.x]
        let blockB : Block? = blocks[to.y][to.x]
        
        //swap the boyes
        if blockA != nil{
            blocks[to.y][to.x] = blockA
            blockA?.column = to.x
            blockA?.row = to.y
        }
        else{
            blocks[to.y][to.x] = nil
        }
        
        if blockB != nil{
            blocks[from.y][from.x] = blockB
            blockB?.column = from.x
            blockB?.row = from.y
        }
        else{
            blocks[from.y][from.x] = nil
        }
    }
    
    func removeMatches(from: Point, to: Point) -> Set<Block>{
        //check for matches
        var match : Set<Block> = []
        match = match.union(checkForMatch(at: to))
        match = match.union(checkForMatch(at: from))
        
        //removeBlocks(in: match)
        return match
    }
    
    func checkForMatch(at: Point) -> Set<Block>{
        var blockType = BlockType.random()
        let row = at.y
        let col = at.x
        
        var match: Set<Block> = []
        var horizontal: Set<Block> = []
        var vertical: Set<Block> = []
        
        if let block = blocks[at.y][at.x]{
            blockType = block.blockType
            horizontal.insert(block)
            vertical.insert(block)
        }
        else{
            return match
        }
        
        var i : Int = col - 1
        while(i >= 0){
            if(blocks[row][i]?.blockType == blockType){
                horizontal.insert(blocks[row][i]!)
            }
            else{
                break
            }
            i-=1
        }
        
        i = col + 1
        while(i < 6){
            if(blocks[row][i]?.blockType == blockType){
                horizontal.insert(blocks[row][i]!)
            }
            else{
                break
            }
            i+=1
        }
        
        //up
        i = row + 1
        while(i < 12){
            if(blocks[i][col]?.blockType == blockType){
                vertical.insert(blocks[i][col]!)
            }
            else{
                break
            }
            i+=1
        }
        
        //down
        i = row - 1
        while(i >= 0){
            if(blocks[i][col]?.blockType == blockType){
                vertical.insert(blocks[i][col]!)
            }
            else{
                break
            }
            i-=1
        }
        
        //insert them into the match
        if(horizontal.count > 2){
            match = match.union(horizontal)
        }
        
        if(vertical.count > 2){
            match = match.union(vertical)
        }
        
        return match
    }
    
    func removeBlocks(in blockSet : Set<Block>) {
        for block in blockSet {
            blocks[block.row][block.column] = nil
        }
    }
}
