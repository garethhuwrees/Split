//
//  Person.swift
//  SPLIT!
//
//  Created by Gareth Rees on 30/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import Foundation
import RealmSwift

class Person: Object {
    @objc dynamic var personName : String = ""
    @objc dynamic var personSpend : Float = 0.0
    @objc dynamic var percentOfBill : Float = 0.0
    
    
}
