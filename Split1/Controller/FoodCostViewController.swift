//
//  FoodCostViewController.swift
//  Split1
//
//  Created by Gareth Rees on 17/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

protocol DidRecieve {
    
    func dataRecieved(data : String) // The method has no body, it just sets out the 'rules of engagement'
}

class FoodCostViewController: UITableViewController {
    
    var deligate : DidRecieve?
    var textPassedOver : String?
    
    let realm = try!Realm()
    var costEntry: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    // Global variable to hold record for 'textPassedOver' food type
    var itemRecord: Results<Item>?
    var dinersFiltered: Results<Person>? // initalise global variable
    var costEntryFiltered: Results<CostEntry>?
    var unitPrice: Bool = false
    
    var currencyPrefix: String = ""
    var screenHeight: Int = 0
    var fontSize: CGFloat = 20
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    
    
    @IBOutlet weak var headerFrame: UILabel!

    @IBOutlet weak var splitterText: UILabel!
    @IBOutlet weak var quantityText: UILabel!
    @IBOutlet weak var spendText: UILabel!
    
    
    
    //MARK:------------------ VIEW DID LOAD & DISAPPEAR ----------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        loadTables()
        
        setAppearance()
        
        if unitPrice == true {
            self.title = textPassedOver! + " *"
        }
        else {
            self.title = textPassedOver!
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {

        updatePercentOfBill()
    }

    //MARK:------------------- INITIATE TABLE VIEW -------------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return costEntry?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "quantityTableCell", for: indexPath) as! QuantityTableCell
        
        let tableTextFont: UIFont = UIFont(name: regularFont, size: fontSize) ?? UIFont(name: "Georgia", size: fontSize)!
        
        // Set font type and colour
        cell.nameLabel.textColor = self.greyColour
        cell.nameLabel.font = tableTextFont
        cell.quantityLabel.textColor = self.greyColour
        cell.quantityLabel.font = tableTextFont
        cell.spendLabel.textColor = self.greyColour
        cell.spendLabel.font = tableTextFont
        
        // set contents
        var spend = costEntry?[indexPath.row].itemSpend ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        let quantity = costEntry?[indexPath.row].itemNumber ?? 0
        
        cell.nameLabel.text = costEntry?[indexPath.row].personName
        cell.quantityLabel.text = String(quantity)
        cell.spendLabel.text = currencyPrefix + spendString
        
        return cell
    }
    
    func formatNumber(numberToFormat: Float, digits: Int) -> String {
        
        let numberformatter = NumberFormatter()
        numberformatter.numberStyle = .decimal
        numberformatter.minimumFractionDigits = digits
        
        let formattedNumber = [numberToFormat].compactMap {number in
            return numberformatter.string(from: NSNumber(value: number))
        }
        
        return formattedNumber[0]
    }

    //MARK: ----------------- ADD SPEND --------------------------- Tested OK
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //let selectedDiner = indexPath.row
        
        if itemRecord?[0].unitPrice == true {
            
            // Increase/Decrease quanitity
            let alert = UIAlertController(title: "Increment Quantity", message: "Add (or subtract) the quantity consumed", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Add One", style: .default, handler: { (action: UIAlertAction) in
                
                var quantity = self.costEntry?[indexPath.row].itemNumber
                
                quantity = quantity! + 1
                
                do {
                    try self.realm.write {
                        self.costEntry?[indexPath.row].itemNumber = quantity ?? 0
                    }
                }
                catch {
                    print("Error updating costEntry record")
                }
                self.updateMenuSpend()
                self.updateDinerSpend()
                tableView.reloadData()
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "(Subtract One)", style: .destructive, handler: { (action: UIAlertAction) in
                
                var quantity = self.costEntry?[indexPath.row].itemNumber
                
                if quantity! > 0 {
                    quantity = quantity! - 1
                }
                
                do {
                    try self.realm.write {
                        self.costEntry?[indexPath.row].itemNumber = quantity ?? 0
                    }
                }
                catch {
                    print("Error updating cost")
                }
                
                self.updateMenuSpend()
                self.updateDinerSpend()
                tableView.reloadData()
                
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
//                print("Cancel button pressed")
            }))
            
            
            self.present(alert, animated: true, completion: nil)
            
        }
        
        if itemRecord?[0].unitPrice == false { // Enter New Spend on Foood Item
        
            var textField = UITextField()
            
            let alert = UIAlertController(title: "Add/Update Spend", message: "What was spent on this item?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                // do nothing
            }))
            
            alert.addAction((UIAlertAction(title: "OK", style: .default, handler: { (action) in
                
                if textField.text!.isEmpty{
                    //Do nothing
                }
                else {
                    let itemCost = (textField.text! as NSString).floatValue
                    
                    if let item = self.costEntry?[indexPath.row] {
                        do {
                            try self.realm.write {
                                item.itemSpend = itemCost
                                if itemCost == 0.0 {
                                    item.itemNumber = 0
                                }
                                else {
                                    item.itemNumber = 1
                                }
                            }
                        }
                        catch {
                            print("Error updating cost")
                        }
                    } // end if
                    
                    self.updateMenuSpend()
                    self.updateDinerSpend()
                    self.loadTables()
                }
            })))
            
            alert.addTextField { (alertTextField) in
                
                alertTextField.placeholder = "\(self.costEntry?[indexPath.row].itemSpend ?? 0.0)"
                textField = alertTextField
                textField.keyboardType = .decimalPad
            } // end alert
            
            present(alert, animated: true, completion: nil)
        
        } // end else
    }
    
    
    
    //MARK:------------------GENERAL FUNCTIONS -------------------------------
    
    func loadTables() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("itemName == %@", textPassedOver ?? "No Name")
        costEntry = costEntry!.sorted(byKeyPath: "personName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        screenHeight = settings?[0].screenHeight ?? 0
        
        item = realm.objects(Item.self)
        itemRecord = item?.filter("itemName == %@", textPassedOver ?? "No Name")
        unitPrice = itemRecord![0].unitPrice
        
        person = realm.objects(Person.self)
        //dinerRecord = diners?.filter("personName == %@", textPassedOver ?? "No Name")
        
        tableView.reloadData()
    }
    
    func setAppearance(){
        
        var tableRowHeight: CGFloat
        
        switch screenHeight {
        case 1136:
            fontSize = 15; tableRowHeight = 26
        case 1334:
            fontSize = 18; tableRowHeight = 30
        default:
            fontSize = 20; tableRowHeight = 32
        }
        
        tableView.separatorColor = UIColor.clear
        tableView.rowHeight = tableRowHeight
        
        splitterText.font = splitterText.font.withSize(fontSize)
        quantityText.font = quantityText.font.withSize(fontSize)
        spendText.font = spendText.font.withSize(fontSize)
        
        headerFrame.layer.cornerRadius = 10.0
        headerFrame.layer.borderColor = orangeColour.cgColor
        headerFrame.layer.borderWidth = 1.0
        
        let leftButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backTapped))
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: regularFont, size: fontSize)!], for: UIControl.State.normal)
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: mediumFont, size: fontSize)!], for: UIControl.State.selected)
        navigationItem.leftBarButtonItem = leftButton

    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        trans.type = CATransitionType.push
        trans.subtype = CATransitionSubtype.fromLeft
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }
    
    
    func updateMenuSpend() {
        
//        itemRecord moved to loadTables() as part of PxQ updat
//        itemRecord = item?.filter("itemName == %@", textPassedOver ?? "No Name")
        
        var menuSpend: Float = 0.0
        var itemCount: Int = 0
        
        let numberOfRecords = costEntry?.count
        
        if numberOfRecords! > 0 {
            for index in 0...numberOfRecords!-1 {

                menuSpend = menuSpend + (costEntry?[index].itemSpend ?? 0.0) * Float(((costEntry?[index].itemNumber)!))
                itemCount = itemCount + (costEntry?[index].itemNumber ?? 0)
                }

                do {
                    try self.realm.write {
                        itemRecord![0].itemSpendNet = menuSpend
                        itemRecord![0].itemNumber = itemCount
                    } // end try
                } // end do
                catch {
                    print("Error updating Diners Spend")
                }
        } // end if
    } // end func
    
    
    func updateDinerSpend() {
        
        var dinerItemRecords: Results<CostEntry>?
        var dinerItemToUpdate: String = textPassedOver!
        var dinerSpend: Float = 0.0
        
        // relaod costEntry with all records
        let fullCostEntry = realm.objects(CostEntry.self)
        
        person = realm.objects(Person.self)
        let numberOfDiners = person?.count ?? 0
        
        if numberOfDiners > 0 {
            for index in 0...numberOfDiners-1 {
                dinerItemToUpdate = person?[index].personName ?? "No Name"
                
                dinerItemRecords = fullCostEntry.filter("personName == %@", dinerItemToUpdate)
                let numberOfDinerItemRecords = dinerItemRecords?.count ?? 0
                dinerSpend = 0.0
                for x in 0...numberOfDinerItemRecords-1 {
                    dinerSpend = dinerSpend + (dinerItemRecords![x].itemSpend) * Float((dinerItemRecords![x].itemNumber))
                }
                
                do {
                    try self.realm.write {
                        person?[index].personSpend = dinerSpend
                    } // end try
                } // end do
                catch {
                    print("Error updating Diners Spend")
                }
            } // end for
        } // end if
    } // end func
    
    func updatePercentOfBill() {
        
        var billTotal: Float = 0.0
        
        let numberOfDiners = person?.count ?? 0
        
        if numberOfDiners > 0 {
            for index in 0...(numberOfDiners - 1){
                billTotal = billTotal + (person?[index].personSpend)!
            }
        } // end if
        
        if numberOfDiners > 0 {
            for index in 0...(numberOfDiners - 1){
                
                var percentOfBill: Float
                
                if billTotal == Float(0.0){
                    percentOfBill = 0.0
                }
                else {
                    percentOfBill = (person?[index].personSpend)! / billTotal
                }
                
                do {
                    try self.realm.write {
                        person?[index].percentOfBill = percentOfBill
                    } // end try
                } // end do
                catch {
                    print("Error updating Person table")
                }
            } // end for
        } // end if
    } // end func
    
    
} // end class




