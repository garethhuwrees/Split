//
//  QuantityTableCell.swift
//  SPLIT!
//
//  Created by Gareth Rees on 25/08/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit

class QuantityTableCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var quantityLabel: UILabel!
    
    @IBOutlet weak var spendLabel: UILabel!
    
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
