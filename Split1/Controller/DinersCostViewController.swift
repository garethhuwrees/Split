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
    var screenHeight: Int = 0
    var fontSize: CGFloat = 20
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    
    @IBOutlet weak var headerFrame: UILabel!
    
    @IBOutlet weak var itemText: UILabel!
    @IBOutlet weak var quantityText: UILabel!
    @IBOutlet weak var spendText: UILabel!
    
    
    
    //MARK: ---------------- VIEW DID LOAD & DISAPPEAR ----------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = textPassedOver!
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        loadTables()
    
        setAppearance()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //updateDinerSpend()
//        updateMenuSpend()
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
        
        // Set contents
        var spend = costEntry?[indexPath.row].itemSpend ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        let quantity = costEntry?[indexPath.row].itemNumber ?? 0
        
        var selectedItem = realm.objects(Item.self)
        selectedItem = (selectedItem.filter("itemName = %@", costEntry![indexPath.row].itemName))
        let unitPrice = selectedItem[0].unitPrice
        
        if unitPrice == true {
            cell.nameLabel.text = costEntry![indexPath.row].itemName + " *"
        }
        else {
            cell.nameLabel.text = costEntry![indexPath.row].itemName
        }
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
    
    //MARK: ----------------- ADD SPEND ---------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let itemName = self.costEntry?[indexPath.row].itemName
        
        item = realm.objects(Item.self) // Reload item
        let selectedItem = item?.filter("itemName == %@", itemName ?? "No Name")
        
        if selectedItem?[0].unitPrice == true {
            
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
        
        if selectedItem?[0].unitPrice == false {
            
            
            var textField = UITextField()
            
            let alert = UIAlertController(title: "Add/Update Spend", message: "What was spent on this item?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                // do nothing
            }))
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                
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
                            print("Error updating costEntry record")
                        }
                    } // end if
                    
                    self.updateDinerSpend()
                    self.updateMenuSpend()
                    self.loadTables()
                }
            }))
            
            alert.addTextField { (alertTextField) in
                
                alertTextField.placeholder = "\(self.costEntry?[indexPath.row].itemSpend ?? 0.0)"
                textField = alertTextField
                textField.keyboardType = .decimalPad
            } // end alert
            
            present(alert, animated: true, completion: nil)
        }
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    //MARK: ------------------GENERAL FUNCTIONS -------------------------------
    
    func loadTables() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("personName == %@", textPassedOver ?? "No Name")
        costEntry = costEntry!.sorted(byKeyPath: "itemName")
        
        person = realm.objects(Person.self)
        dinerRecord = person?.filter("personName == %@", textPassedOver ?? "No Name")
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        screenHeight = settings?[0].screenHeight ?? 0
        
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
        
        itemText.font = itemText.font.withSize(fontSize)
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
    
    func updateDinerSpend() {
        
        let numberOfRecords = self.costEntry?.count ?? 0
        var totalBill: Float = 0.0
        if numberOfRecords > 0 {
            for index in 0...(numberOfRecords-1) {
                totalBill = totalBill + (costEntry![index].itemSpend) * Float(costEntry![index].itemNumber)
            } // end for
            do {
                try self.realm.write {
                    let selectedDiner = dinerRecord?[0]
                    selectedDiner?.personSpend = totalBill
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
        var menuSpend: Float
        var itemCount: Int
        
        // relaod costEntry with all records
        let fullCostEntry = realm.objects(CostEntry.self)
        
        // reload items with all records
        item = realm.objects(Item.self)
        let numberOfMenuItems = item?.count ?? 0
        
        if numberOfMenuItems > 0 {
            for index in 0...numberOfMenuItems-1 {
                menuItemToUpdate = item?[index].itemName ?? "No Name" // process each item.itemName in turn
                
                menuItemRecords = fullCostEntry.filter("itemName == %@", menuItemToUpdate)
                let numberOfMenuItemRecords = menuItemRecords?.count ?? 0
                menuSpend = 0.0
                itemCount = 0
                
                for x in 0...numberOfMenuItemRecords-1 {
                    menuSpend = menuSpend + (menuItemRecords![x].itemSpend * Float(menuItemRecords![x].itemNumber))
                    itemCount = itemCount + (menuItemRecords?[x].itemNumber ?? 0)
                }
                do {
                    try self.realm.write {
                        item?[index].itemSpendNet = menuSpend
                        item?[index].itemNumber = itemCount
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

}
