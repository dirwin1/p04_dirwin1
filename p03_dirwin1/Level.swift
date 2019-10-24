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
    private var upComingRow = [Block?](repeating: nil, count: numColumns)
    var lockedPositions : Set<Point> = []
    
    func block(atColumn column: Int, row: Int) -> Block? {
        if(column < 0 || column >= numColumns){
            return nil
        }
        if(row < 0 || row >= numRows){
            return nil
        }
        return blocks[row][column]
    }
    
    func isLocked(pos: Point) -> Bool{
        return lockedPositions.contains(pos)
    }
    
    func lockPosition(pos: Point){
        lockedPositions.insert(pos)
    }
    
    func lockPosition(positions: Set<Point>){
        lockedPositions = lockedPositions.union(positions)
    }
    
    func unlockPosition(pos: Point){
        lockedPositions.remove(pos)
    }
    
    func unlockPosition(positions: Set<Point>){
        for pos in positions{
            lockedPositions.remove(pos)
        }
    }

    func shuffle() -> Set<Block> {
        return initializeBlocks()
    }
    
    func startFall() -> Set<Block>{
        var fallingBoyes: Set<Block> = []
        for row in 0..<numRows{
            for col in 0..<numColumns{
                if block(atColumn: col, row: row) == nil && block(atColumn: col, row: row + 1) != nil && block(atColumn: col, row: row + 1)?.falling == false && !isLocked(pos: Point(x: col, y: row)) && !isLocked(pos: Point(x: col, y: row + 1)){
                    //fall down
                    block(atColumn: col, row: row + 1)?.falling = true
                    fallingBoyes.insert(block(atColumn: col, row: row + 1)!)
                }
            }
        }
        return fallingBoyes
    }
    
    func fall() -> (Set<Block>, Set<Block>, Set<Block>){
        var movedBoys: Set<Block> = []
        var landedBoyes: Set<Block> = []
        var matchedBoyes: Set<Block> = []
        for row in 0..<numRows{
            for col in 0..<numColumns{
                if block(atColumn: col, row: row) == nil && block(atColumn: col, row: row + 1) != nil
                    && !isLocked(pos: Point(x: col, y: row)) && !isLocked(pos: Point(x: col, y: row + 1)) {
                    
                    //fall down
                    movedBoys.insert(blocks[row+1][col]!)
                    blocks[row][col] = blocks[row+1][col]
                    blocks[row][col]?.column = col
                    blocks[row][col]?.row = row
                    blocks[row+1][col] = nil
                    
                    if(row == 0){
                        blocks[row][col]?.falling = false;
                        landedBoyes.insert(blocks[row][col]!)
                        //check for matches
                        let myMatches = checkForMatch(at: Point(x: col, y: row))
                        if myMatches.isEmpty{
                            blocks[row][col]!.chainCount = 1
                        }
                        else{
                            matchedBoyes = matchedBoyes.union(myMatches)
                        }
                    }
                    else if(blocks[row-1][col] != nil){
                        //check for landing
                        if(blocks[row-1][col]?.falling == false){
                            blocks[row][col]?.falling = false;
                            landedBoyes.insert(blocks[row][col]!)
                            //check for matches
                            let myMatches = checkForMatch(at: Point(x: col, y: row))
                            if myMatches.isEmpty{
                                blocks[row][col]!.chainCount = 1
                            }
                            else{
                                matchedBoyes = matchedBoyes.union(myMatches)
                            }
                        }
                    }
                    else{
                        //this block must be falling
                        blocks[row][col]?.falling = true;
                    }
                }
            }
        }
        return (movedBoys, landedBoyes, matchedBoyes)
    }
    
    private func initializeBlocks() -> Set<Block> {
        var set: Set<Block> = []

        // 1
        for column in 0..<numColumns {
            for row in 0..<Int(arc4random_uniform(UInt32(numRows - 5))) {
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
        
        let newRow = createNewRow()
        set = set.union(newRow)
      return set
    }
    
    private func createNewRow() -> Set<Block>{
        var set: Set<Block> = []
        
        for col in 0..<numColumns{
            var blockType: BlockType
            
            repeat{
                blockType = BlockType.random()
            } while (col >= 2 &&
                upComingRow[col-1]?.blockType == blockType &&
                upComingRow[col-2]?.blockType == blockType)
            
            let block = Block(column: col, row: -1, blockType: blockType)
            upComingRow[col] = block
            
            set.insert(block)
        }
        
        return set
    }
    
    func performSwap(from: Point, to: Point) -> Set<Block>{
        let blockA : Block? = blocks[from.y][from.x]
        let blockB : Block? = blocks[to.y][to.x]
        
        //swap the boyes
        if blockA != nil{
            blocks[to.y][to.x] = blockA
            blockA?.column = to.x
            blockA?.row = to.y
            //blockA?.chainCount = 1
        }
        else{
            blocks[to.y][to.x] = nil
        }
        
        if blockB != nil{
            blocks[from.y][from.x] = blockB
            blockB?.column = from.x
            blockB?.row = from.y
            //blockB?.chainCount = 1
        }
        else{
            blocks[from.y][from.x] = nil
        }
        
        //check for matches
        let matchTo = checkForMatch(at: to)
        let matchFrom = checkForMatch(at: from)
        let matches = matchTo.union(matchFrom)
        
        return matches
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
            if isLocked(pos: Point(x:i, y:row)){
                break
            }
            
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
            if isLocked(pos: Point(x:i, y:row)){
                break
            }
            
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
            if isLocked(pos: Point(x:col, y:i)){
                break
            }
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
            if isLocked(pos: Point(x:col, y:i)){
                break
            }
            
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
        //first calculate highest chain in the match
        var highestChain: Int = 1
        for b in blockSet{
            if b.chainCount > highestChain {
                highestChain = b.chainCount
            }
        }
        
        for b in blockSet {
            blocks[b.row][b.column] = nil
            //increment chain for the above block
            let above = block(atColumn: b.column, row: b.row + 1)
            if above != nil{
                above!.chainCount = highestChain + 1
            }
        }
    }
    
    func addRow() -> (Set<Block>, Set<Block>, Set<Block>, Bool){
        var movedBoyes: Set<Block> = []
        var newBoyes: Set<Block> = []
        var matchedBoyes: Set<Block> = []
        var survive: Bool = true
        //check for survival
        for col in 0..<numColumns{
            if blocks[numRows-2][col] != nil{
                survive = false
            }
        }
        
        //move all of the boyes up
        for row in (1..<numRows).reversed(){
            for col in 0..<numColumns{
                blocks[row][col] = blocks[row-1][col]
                if(blocks[row][col] != nil){
                    blocks[row][col]?.row = row
                    movedBoyes.insert(blocks[row][col]!)
                }
            }
        }
        //move the upcoming row into the real row
        for col in 0..<numColumns{
            let block = upComingRow[col]
            block?.row = 0
            block?.sprite?.color = UIColor.white
            blocks[0][col] = block
            movedBoyes.insert(block!)
        }
        //create new upcoming boyes
        newBoyes = createNewRow()
        movedBoyes = movedBoyes.union(newBoyes)
        
        //check for matches on the new row
        for col in 0..<numColumns{
            matchedBoyes = matchedBoyes.union(checkForMatch(at: Point(x: col, y: 0)))
        }
        
        //fill the bottom up with randos
        return (movedBoyes, newBoyes, matchedBoyes, survive)
    }
}
