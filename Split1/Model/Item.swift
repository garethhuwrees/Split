//
//  Item.swift
//  SPLIT!
//
//  Created by Gareth Rees on 30/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import Foundation
import RealmSwift

class Item: Object {
    @objc dynamic var itemName : String = ""
    @objc dynamic var itemSpendNet : Float = 0.0
    @objc dynamic var itemNumber : Int = 0
    @objc dynamic var itemUnitPrice : Float = 0.0
    @objc dynamic var unitPrice: Bool = false
    
    
}
