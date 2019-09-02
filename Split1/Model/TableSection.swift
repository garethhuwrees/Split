//
//  TableSection.swift
//  SPLIT!
//
//  Created by Gareth Rees on 31/08/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import Foundation

class TableSection {
    
    let foodType: String
    var nameArray: Array<String>
    var quantityArray: Array<Int>
    var spendArray: Array<Float>
    
    init(food: String, person: Array<String>, quantity: Array<Int>, spend: Array<Float>) {
        foodType = food
        nameArray = person
        quantityArray = quantity
        spendArray = spend
        
    }
    
    
}
