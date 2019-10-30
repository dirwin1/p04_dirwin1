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
    var upComingRow = [Block?](repeating: nil, count: numColumns)
    var lockedPositions : Set<Point> = []
    var chainBlocksCount : Int = 0
    var fallingBlocksCount : Int = 0
    var chainCount = 2
    
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
    
    func fall() -> (Set<Block>, Set<Block>, Set<Block>){
        var movedBoys: Set<Block> = []
        var landedBoyes: Set<Block> = []
        var matchedBoyes: Set<Block> = []
        
        //move blocks down
        for row in 0..<numRows{
            for col in 0..<numColumns{
                //fall down
                if row > 0 && !isLocked(pos: Point(x: col, y: row)) && !isLocked(pos: Point(x: col, y: row - 1)) {
                    if let b = block(atColumn: col, row: row){
                        if let below = block(atColumn: col, row: row - 1){
                            //there is someone beneath us, but we may be able to start our fall countdown
                            if below.falling == true {
                                if b.falling == false {
                                    b.falling = true
                                    fallingBlocksCount += 1
                                }
                                
                                b.fallCounter += 1
                            }
                        }
                        else{
                            //Nobody below us, we can fall if we need to
                            if b.falling == false {
                                b.falling = true
                                fallingBlocksCount += 1
                            }
                            
                            b.fallCounter += 1
                            if b.fallCounter >= b.timeToFall {
                                //fall
                                blocks[row][col] = nil
                                b.row = row - 1
                                blocks[row-1][col] = b

                                movedBoys.insert(b)
                            }
                        }
                    }
                    /*
                    //fall down
                    movedBoys.insert(blocks[row+1][col]!)
                    blocks[row][col] = blocks[row+1][col]
                    blocks[row][col]!.column = col
                    blocks[row][col]!.row = row
                    blocks[row+1][col] = nil
                    if blocks[row][col]!.falling == false{
                        blocks[row][col]!.falling = true
                        fallingBlocksCount += 1
                    }
 */
                }
            }
        }
        
        for row in 0..<numRows{
            for col in 0..<numColumns{
                //check for landing
                if let b = blocks[row][col]{
                    if b.falling == true{
                        var landed: Bool = false
                        if(row == 0){
                            //landed
                            landed = true
                        }
                        else if (blocks[row-1][col] != nil && blocks[row-1][col]?.falling == false)  {
                            //landed
                            landed = true
                        }
                        
                        if landed {
                            b.falling = false
                            b.fallCounter = 0
                            fallingBlocksCount -= 1
                            
                            landedBoyes.insert(b)
                            //check for matches
                            let myMatches = checkForMatch(at: Point(x: col, y: row))
                            if myMatches.isEmpty{
                                if b.inChain == true{
                                    b.inChain = false
                                    chainBlocksCount -= 1
                                }
                            }
                            else{
                                matchedBoyes = matchedBoyes.union(myMatches)
                            }
                        }
                    }
                }
            }
        }
        
        return (movedBoys, landedBoyes, matchedBoyes)
    }
    
    func endChain(){
        if chainCount > 2 && chainBlocksCount == 0 {
            chainCount = 2
        }
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
        }
        else{
            blocks[to.y][to.x] = nil
        }
        
        if blockB != nil{
            blocks[from.y][from.x] = blockB
            blockB!.column = from.x
            blockB!.row = from.y
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
            
            if(blocks[row][i]?.blockType == blockType && blocks[row][i]!.falling == false){
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
            
            if(blocks[row][i]?.blockType == blockType && blocks[row][i]!.falling == false){
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
            if(blocks[i][col]?.blockType == blockType && blocks[i][col]!.falling == false){
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
            
            if(blocks[i][col]?.blockType == blockType && blocks[i][col]!.falling == false){
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
        for b in blockSet {
            //increment chain for the above block
            var offset: Int = 1
            var cont: Bool = true
            while offset + b.row < numRows && cont{
                let above = block(atColumn: b.column, row: b.row + offset)
                if above != nil{
                    if above!.inChain == false {
                        above!.inChain = true
                        chainBlocksCount += 1
                    }
                    offset += 1
                }
                else{
                    cont = false
                }
            }
            
            //remove the boye
            blocks[b.row][b.column] = nil
            if b.inChain == true{
                chainBlocksCount -= 1
            }
        }
    }
    
    func addRow() -> (Set<Block>, Set<Block>, Set<Block>, Bool){
        var movedBoyes: Set<Block> = []
        var newBoyes: Set<Block> = []
        var matchedBoyes: Set<Block> = []
        
        //check for survival
        for col in 0..<numColumns{
            if blocks[numRows-2][col] != nil{
                return (movedBoyes, newBoyes, matchedBoyes, false)
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
        return (movedBoyes, newBoyes, matchedBoyes, true)
    }
    
    func checkForBouncers() -> (Set<Block>, Set<Block>){
        var bouncers : Set<Block> = []
        var normal : Set<Block> = []
        
        for col in 0..<numColumns{
            if(blocks[numRows-1][col] != nil || blocks[numRows-2][col] != nil){
                for row in 0..<numRows{
                    if !isLocked(pos: Point(x:col, y:row)){
                        if blocks[row][col] != nil{
                            bouncers.insert(blocks[row][col]!)
                        }
                    }
                }
            }
            else{
                for row in 0..<numRows{
                    if blocks[row][col] != nil{
                        normal.insert(blocks[row][col]!)
                    }
                }
            }
        }
        return (normal, bouncers)
    }
}
