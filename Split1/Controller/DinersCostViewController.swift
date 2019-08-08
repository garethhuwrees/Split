//
//  DinersCostViewController.swift
//  Split1
//
//  Created by Gareth Rees on 28/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

protocol CanRecieve {
    
    func dataRecieved(data : String) // The method has no body, it just sets out the 'rules of engagement'
    
}

class DinersCostViewController: UITableViewController {
    
    var deligate : CanRecieve?
    var textPassedOver : String?

    
    let realm = try!Realm()
    var costEntry: Results<CostEntry>?
    var person: Results<Person>?
    var dinerRecord: Results<Person>? // initalise global variable
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    var currencyPrefix: String = ""
    
    
    // Set table text colour and font
    let greyText: UIColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let tableTextFont: UIFont = UIFont(name: "Chalkboard SE", size: 18) ?? UIFont(name: "Regular", size: 18)!
    
    //---------------- VIEW DID LOAD & DISAPPEAR ----------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = textPassedOver!
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        loadCostEnryItems()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //updateDinerSpend()
        updateMenuSpend()
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
        
        // Set contents
        var spend = costEntry?[indexPath.row].itemSpend ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        cell.leftCellLabel.text = costEntry?[indexPath.row].itemName
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
    
    //MARK: ----------------- ADD SPEND ---------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
            
                    self.updateDinerSpend()
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
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    //MARK: ------------------GENERAL FUNCTIONS -------------------------------
    
    func loadCostEnryItems() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("personName == %@", textPassedOver ?? "No Name")
        costEntry = costEntry!.sorted(byKeyPath: "itemName")
        
        person = realm.objects(Person.self)
        dinerRecord = person?.filter("personName == %@", textPassedOver ?? "No Name")
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        tableView.reloadData()
    }
    
    func updateDinerSpend() {
        
        let numberOfRecords = self.costEntry?.count ?? 0
        var totalBill: Float = 0.0
        if numberOfRecords > 0 {
            for index in 0...(numberOfRecords-1) {
                totalBill = totalBill + (costEntry?[index].itemSpend)!
            } // end for
            do {
                try self.realm.write {
                    let selectedDiner = dinerRecord?[0]
                    selectedDiner?.personSpendNet = totalBill
                } // end try
            } // end do
            catch {
                print("Error updating Diners Spend")
            }
        } // end if
        
    }
    
    func updateMenuSpend() {
        
        var menuItemRecords: Results<CostEntry>?
        var menuItemToUpdate: String = ""
        var menuSpend: Float = 0.0
        
        // relaod costEntry with all records
        costEntry = realm.objects(CostEntry.self)
        
        item = realm.objects(Item.self)
        let numberOfMenuItems = item?.count ?? 0
        
        if numberOfMenuItems > 0 {
            for index in 0...numberOfMenuItems-1 {
                menuItemToUpdate = item?[index].itemName ?? "No Name"
                
                menuItemRecords = costEntry?.filter("itemName == %@", menuItemToUpdate)
                let numberOfMenuItemRecords = menuItemRecords?.count ?? 0
                menuSpend = 0.0
                for x in 0...numberOfMenuItemRecords-1 {
                    menuSpend = menuSpend + (menuItemRecords?[x].itemSpend ?? 0.0)
                }
                
                do {
                    try self.realm.write {
                        item?[index].itemSpendNet = menuSpend
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

}
