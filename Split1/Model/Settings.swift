//
//  Settings.swift
//  Split1
//
//  Created by Gareth Rees on 29/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import Foundation
import RealmSwift

class Settings: Object {
    @objc dynamic var gratuity : Float = 0.0
    @objc dynamic var taxRate : Float = 0.0
    @objc dynamic var billTotalSpend : Float = 0.00
    @objc dynamic var billWithTip : Float = 0.00
    @objc dynamic var billRounded: Float = 0.0
    @objc dynamic var currencySymbol : String = ""
    @objc dynamic var currencyPrefix : String = ""
    @objc dynamic var spendType : String = "" // "TotalSpend", "SpendPlusTip", "FixedSpend"
    // the enum type cannot be represented in object-c
    @objc dynamic var phoneType : String = ""
    @objc dynamic var iosVersion : String = ""
    @objc dynamic var screenHeight : Int = 0
    @objc dynamic var roundingOn : Bool = false

}
