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
    @objc dynamic var totalBill : Float = 0.00
    @objc dynamic var billWithGratuity : Float = 0.00
    @objc dynamic var billRounded: Float = 0.0
    @objc dynamic var currencySymbol : String = ""
    @objc dynamic var currencyPrefix : String = ""
    @objc dynamic var phoneType : String = ""
    @objc dynamic var iosVersion : String = ""
    @objc dynamic var screenHeight : Int = 0
    @objc dynamic var roundBill : Bool = false

}
