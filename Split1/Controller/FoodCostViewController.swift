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
    var menuItemsFiltered: Results<Item>?
    var dinersFiltered: Results<Person>? // initalise global variable
    var costEntryFiltered: Results<CostEntry>?
    
    var currencyPrefix: String = ""
    
    let greyText: UIColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let tableTextFont: UIFont = UIFont(name: "Chalkboard SE", size: 18) ?? UIFont(name: "Regular", size: 18)!
 
    //MARK:------------------ VIEW DID LOAD & DISAPPEAR ----------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = textPassedOver!
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        loadTables()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        updateDinerSpend()
        updatePercentOfBill()
    }

    //MARK:------------------- INITIATE TABLE VIEW -------------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return costEntry?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
        
        // Set font type and colour
        cell.leftCellLabel.textColor = self.greyText
        cell.leftCellLabel.font = self.tableTextFont
        cell.rightCellLabel.textColor = self.greyText
        cell.rightCellLabel.font = self.tableTextFont
        
        // set contents
        var spend = costEntry?[indexPath.row].itemSpend ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        cell.leftCellLabel.text = costEntry?[indexPath.row].personName
        cell.rightCellLabel.text = currencyPrefix + spendString
        
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
        
        let selectedDiner = indexPath.row
        
        print("Selected Diner is \(selectedDiner)")
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add/Update Spend", message: "What was spent on this item?", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Apply", style: .default) { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                let itemCost = (textField.text! as NSString).floatValue
                
                if let item = self.costEntry?[indexPath.row] {
                    do {
                        try self.realm.write {
                            item.itemSpend = itemCost
                        }
                    }
                    catch {
                        print("Error updating cost")
                    }
                } // end if
                
                //self.updateDinerSpendOld(tableRow: selectedDiner)
                self.updateMenuSpend()
                self.tableView.reloadData()
            }
            
        }
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.costEntry?[indexPath.row].itemSpend ?? 0.0)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end alert
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    
    
    
    //MARK:------------------GENERAL FUNCTIONS -------------------------------
    
    func loadTables() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("itemName == %@", textPassedOver ?? "No Name")
        costEntry = costEntry!.sorted(byKeyPath: "personName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        item = realm.objects(Item.self)
//        MenuItemsFiltered = menuItems?.filter("menuItem == %@", textPassedOver ?? "No Name")
        
        person = realm.objects(Person.self)
        //dinerRecord = diners?.filter("personName == %@", textPassedOver ?? "No Name")
        
        tableView.reloadData()
    }
    
    
    func updateMenuSpend() {
        
        menuItemsFiltered = item?.filter("itemName == %@", textPassedOver ?? "No Name")
        
        var menuSpend: Float = 0.0
        
        let numberOfRecords = costEntry?.count
        
        if numberOfRecords! > 0 {
            for index in 0...numberOfRecords!-1 {

                menuSpend = menuSpend + (costEntry?[index].itemSpend ?? 0.0)
                }

                print("Item Spend =\(menuSpend)")

                do {
                    try self.realm.write {
                        menuItemsFiltered![0].itemSpendNet = menuSpend
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
        costEntry = realm.objects(CostEntry.self)
        
        person = realm.objects(Person.self)
        let numberOfDiners = person?.count ?? 0
        
        if numberOfDiners > 0 {
            for index in 0...numberOfDiners-1 {
                //print("MenuItem = \(menuItems?[index].menuItem ?? "No Name")")
                dinerItemToUpdate = person?[index].personName ?? "No Name"
                
                dinerItemRecords = costEntry?.filter("personName == %@", dinerItemToUpdate)
                let numberOfDinerItemRecords = dinerItemRecords?.count ?? 0
                dinerSpend = 0.0
                for x in 0...numberOfDinerItemRecords-1 {
                    dinerSpend = dinerSpend + (dinerItemRecords?[x].itemSpend ?? 0.0)
                }
                
                //print("Item Spend =\(menuSpend)")
                
                do {
                    try self.realm.write {
                        person?[index].personSpendNet = dinerSpend
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
                billTotal = billTotal + (person?[index].personSpendNet)!
            }
        } // end if
        
        if numberOfDiners > 0 {
            for index in 0...(numberOfDiners - 1){
                let percentOfBill = (person?[index].personSpendNet)! / billTotal
                
                do {
                    try self.realm.write {
                        person?[index].percentOfBill = percentOfBill
                    } // end try
                } // end do
                catch {
                    print("Error updating Diners Spend")
                }
            } // end for
        } // end if
    } // end func
    
    
} // end class

// This was used to update individual diner spend and called from the ADD SPEND functio
// It was replaced with an update all diner spend function called from ViewDidDisappear
    
//func updateDinerSpendOld(tableRow:Int) { // Tested OK
//
//    let diner = costEntry![tableRow].personName
//
//    print("Selected Diner Name is \(diner)")
//
//    //costEntry = realm.objects(CostEntry.self) // reset costEnrty
//    //costEntryFiltered = realm.objects(CostEntry.self)
//    costEntryFiltered = realm.objects(CostEntry.self) // reset costEntryFiltered
//    costEntryFiltered = costEntryFiltered?.filter("personName == %@", diner)
//    dinersFiltered = person?.filter("personName == %@", diner)
//
//    let numberOfRecords = self.costEntryFiltered?.count ?? 0
//    var totalBill: Float = 0.0
//    if numberOfRecords > 0 {
//        for index in 0...(numberOfRecords-1) {
//            totalBill = totalBill + (costEntryFiltered?[index].itemSpend)!
//        } // end for
//        do {
//            try self.realm.write {
//                let selectedDiner = dinersFiltered?[0]
//                selectedDiner?.personSpendNet = totalBill
//            } // end try
//        } // end do
//        catch {
//            print("Error updating Diners Spend")
//        }
//    } // end if
//}



