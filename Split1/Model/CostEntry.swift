//
//  Associate.swift
//  Split1
//
//  Created by Gareth Rees on 01/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import Foundation
import RealmSwift

class CostEntry: Object {
    @objc dynamic var personName: String = ""
    @objc dynamic var itemName: String = ""
    @objc dynamic var itemSpend: Float = 0.0
    @objc dynamic var itemNumber: Int = 0
    
    // Set up the inverse relationships
//    var consumedBy = LinkingObjects(fromType: Splitter.self, property: "consumes")
//    var containedIn = LinkingObjects(fromType: Menu.self, property: "available")
    
}
