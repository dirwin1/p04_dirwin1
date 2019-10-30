//
//  Profile.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/30/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation

class Profile{
    var highScore: Int = 0
    var blocksBroken: Int = 0
    var highestCombo: Int = 0
    var highestChain: Int = 0
    
    func setHighestCombo(combo: Int){
        if combo > highestCombo {
            highestCombo = combo
        }
    }
    
    func setHighestChain(chain: Int){
        if chain > highestChain {
            highestChain = chain
        }
    }
    
    func setHighScore(score: Int){
        if score > highScore{
            highScore = score
        }
    }
}
