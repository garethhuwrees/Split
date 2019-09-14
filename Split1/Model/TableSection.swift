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
    var quantityArray: Array<String>
    var spendArray: Array<String>
    
    init(food: String, person: Array<String>, quantity: Array<String>, spend: Array<String>) {
        foodType = food
        nameArray = person
        quantityArray = quantity
        spendArray = spend
        
    }
    
    // Note: had to convert quantityAttay from Array<Int> to Array<Float> so that an empty string arry could be used
    // in the total section.
    // spendArray changed for consistancey
    
    
}
