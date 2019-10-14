//
//  Swap.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/11/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//
import Foundation

struct Swap: CustomStringConvertible {
  let blockA: Block
  let blockB: Block
  
  init(blockA: Block, blockB: Block) {
        self.blockA = blockA
      self.blockB = blockB
  }
  
  var description: String {
    return "swap \(blockA) with \(blockB)"
  }
}
