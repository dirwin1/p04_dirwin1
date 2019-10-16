//
//  Point.swift
//  p03_dirwin1
//
//  Created by Dylan Irwin on 10/14/19.
//  Copyright © 2019 Dylan Irwin. All rights reserved.
//

import Foundation

struct Point : Hashable{
    var x: Int
    var y: Int
    
    init(x: Int, y: Int){
        self.x = x
        self.y = y
    }
}
