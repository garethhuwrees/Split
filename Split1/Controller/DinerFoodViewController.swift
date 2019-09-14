//
//  DinerFoodViewController.swift
//  SPLIT!
//
//  Created by Gareth Rees on 10/08/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

class DinerFoodViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

//class DinerFoodViewController: UITableViewController {

    let realm = try!Realm()
    
    var costItems: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    var selectedDiner: String = "" // can these both be changed to "selectedRow"
    var selectedFood: String = ""
    var newCostEntry: CostEntry = CostEntry()
    var currencyPrefix: String = ""
    var roundingOn: Bool = false
    var percentageTip: Float = 0.0
    var screenHeight: Int = 0
    

    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    
    var fontSize: CGFloat = 20
    let splitFont: String = "Lemon-Regular"
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
    
    @IBOutlet weak var splitterTableView: UITableView!
    @IBOutlet weak var foodTableView: UITableView!
    
    @IBOutlet weak var splitterText: UITextField!
    @IBOutlet weak var foodText: UITextField!
    
    
    // MARK:--------------------- VIEWDIDLOAD & DISAPPEAR ------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Table"
        
        splitterTableView.delegate = self
        splitterTableView.dataSource = self
        splitterTableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        foodTableView.delegate = self
        foodTableView.dataSource = self
        foodTableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        
        loadTables()
        setAppearance()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        splitterTableView.reloadData()
        foodTableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        // Update Total Spend (Settings)
        var totalBill: Float = 0.0
        let numberOfDiners = person?.count ?? 0
        
        if numberOfDiners > 0 {
            for n in 0...(numberOfDiners-1) {
                totalBill = totalBill + person![n].personSpend
            } // end for
        }
        else {
            // leave totalBill = 0.0
        }
        
        do{
            try realm.write {
                self.settings?[0].totalSpend = totalBill
            }
        } catch {
            print("Error saving settings, \(error)")
        }
        
    }
    
    
    // MARK:------------------- TABLE PROTOCOLS ------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        if tableView.tag == 1 {
            return person?.count ?? 1
        }
        else {
            return item?.count ?? 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tableTextFont: UIFont = UIFont(name: regularFont, size: fontSize) ?? UIFont(name: "Georgia", size: fontSize)!
        
        if tableView.tag == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "quantityTableCell", for: indexPath) as! QuantityTableCell
            
            // Set font type and colour
            cell.nameLabel.textColor = self.greyColour
            cell.nameLabel.font = tableTextFont
            cell.spendLabel.textColor = self.greyColour
            cell.spendLabel.font = tableTextFont
            
            var spend = (person?[indexPath.row].personSpend) ?? 0.0
            spend = (spend * 100).rounded() / 100
            let spendString = formatNumber(numberToFormat: spend, digits: 2)
            
            cell.nameLabel.text = person?[indexPath.row].personName
            cell.spendLabel.text = currencyPrefix + spendString
            cell.quantityLabel.text = ""
            
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "quantityTableCell", for: indexPath) as! QuantityTableCell
            
            // Set font type and colour
            cell.nameLabel.textColor = self.greyColour
            cell.nameLabel.font = tableTextFont
            cell.spendLabel.textColor = self.greyColour
            cell.spendLabel.font = tableTextFont
            
            var spend = item?[indexPath.row].itemSpendNet ?? 0.0
            spend = (spend * 100).rounded() / 100
            let spendString = formatNumber(numberToFormat: spend, digits: 2)
            
            if item?[indexPath.row].unitPrice == true {
                cell.nameLabel.text = item![indexPath.row].itemName + " *"
            }
            else {
                cell.nameLabel.text = item![indexPath.row].itemName
            }
            cell.spendLabel.text = currencyPrefix + spendString
            cell.quantityLabel.text = ""
            
            return cell
        }
        
    }
    
    //MARK:---------------------- SEGUE TO COST ENTRY ------------------------------
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.tag == 1 {
        selectedDiner = person?[indexPath.row].personName ?? "No Name"
        
        performSegue(withIdentifier: "gotoDinerCostEntry", sender: self)
            
        }
        
        if tableView.tag == 2 {
            selectedFood = item?[indexPath.row].itemName ?? "No Name"
            
            performSegue(withIdentifier: "gotoFoodCostEntry", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoDinerCostEntry" {
            
            let destinationVC = segue.destination as! DinersCostViewController
            
            destinationVC.textPassedOver = "\(selectedDiner)"
            
        }
        if segue.identifier == "gotoFoodCostEntry" {
            
            let destinationVC = segue.destination as! FoodCostViewController
            
            destinationVC.textPassedOver = "\(selectedFood)"
            
        }
        
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .right {
            backTapped()
        }
    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        trans.type = CATransitionType.push
        trans.subtype = CATransitionSubtype.fromLeft
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }
        
    //MARK:---------------------- EDIT ACTIONS FOR ROWS ------------------------------
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?{
        
        if tableView.tag == 1 {
            let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
                
//          Find & Delete Related Cost Entry Records
            if let record = self.person?[indexPath.row] {
                do {
                    try self.realm.write {
                        let recordsToDelete = self.costItems?.filter("personName == %@", record.personName)

                        let numberOfRecords = recordsToDelete?.count ?? 0

                        if numberOfRecords > 0 {
                            for _ in 0...(numberOfRecords-1) {
                                var costItemToDelete = recordsToDelete![0]
                                self.realm.delete(costItemToDelete)
                                costItemToDelete = CostEntry()
                            }
                        }
                        else {
                            print("No records to delete")
                        }
                        // Delete Diners Record
                        self.realm.delete(record)

                    } // end try

                } catch {
                    print("Error deleting record, \(error)")
                } // end catch
            } // end if let

            self.loadTables()
            self.updateMenuItemSpend()
                
            } // end action
            
            delete.backgroundColor = .red
            return [delete]
            
        } // end if tableView.tag == 1
        
        if tableView.tag == 2 {
            
            let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
                
                if let record = self.item?[indexPath.row] {
                    do {
                        try self.realm.write {

                            let recordsToDelete = self.costItems?.filter("itemName == %@", record.itemName)
                            let numberOfRecords = recordsToDelete?.count ?? 0

                            // Delete Cost Entry Records
                            if numberOfRecords > 0 {
                                for _ in 0...(numberOfRecords-1) {
                                    var costItemToDelete = recordsToDelete![0]
                                    self.realm.delete(costItemToDelete)
                                    costItemToDelete = CostEntry()
                                }
                            }
                            else {
                                print("No records to delete")
                            }
                            // Delete Menu Record
                            self.realm.delete(record)

                        } // end try

                    } catch {
                        print("Error deleting record, \(error)")
                    } // end catch
                } // end if let
                
                self.loadTables()
                self.updateDinersSpend()
               
            } // end action
            
            delete.backgroundColor = .red
            
            let selecectdItem = item?[indexPath.row].itemName
            let selectedRecord = item?.filter("itemName == %@", selecectdItem!)
            let unitPrice = selectedRecord![0].unitPrice
            let numberOfItems = selectedRecord![0].itemNumber
            
            if unitPrice == false {
                
                var actionTitle = "Set\nUnit Price"
                if screenHeight <= 1334 {
                    actionTitle = "Set Unit Price"
                }
                
                let price = UITableViewRowAction(style: .normal, title: actionTitle) { action, index in
                    
                    if numberOfItems == 0 {
                        let title = "Set Unit Price"
                        let message = "Enter Price and Confirm\n(This cannot be undone)"
                        
                        self.unitPriceAlert(title: title, message: message, record: selectedRecord!)
                        }
                    else {
                        
                        let spendWarning = UIAlertController(title: "Spend Recorded", message: "This will overwrite the existing item spend", preferredStyle: UIAlertController.Style .alert)
                        
                        spendWarning.addAction(UIAlertAction(title: "Cancel", style: .destructive
                            , handler: { (UIAlertAction) in
                                // Do Nothing
                        }))
                        
                        spendWarning.addAction(UIAlertAction(title: "Proceed", style: .default, handler: { (UIAlertAction) in
                            
                            let title = "Set Unit Price"
                            let message = "Enter Price and Confirm\n(This cannot be undone)"
                            
                            self.unitPriceAlert(title: title, message: message, record: selectedRecord!)
                            
                            // Also update existing costEntry.itemSpend = item.unitPrice
                        }))
                        
                        self.present(spendWarning, animated: true, completion: nil)
                    }
                } // end action

                price.backgroundColor = self.greenColour
                return [delete, price]
            } // end if unitPrice == false
            
            if unitPrice == true {
                
                var actionTitle = "Update\nUnit Price"
                if screenHeight <= 1334 {
                    actionTitle = "Update Unit Price"
                }
                
                let price = UITableViewRowAction(style: .normal, title: actionTitle) { action, index in
                   
                    let title = "Update Unit Price"
                    let message = "Enter Price and Confirm\n(This will overwrite exising spend?"
                    
                    self.unitPriceAlert(title: title, message: message, record: selectedRecord!)
                }
                price.backgroundColor = .blue
                return [delete, price]
            } // end if unitPrice == true
        }

        return []
    }

    
    func unitPriceAlert(title: String, message: String, record: Results<Item> ){
        
        var priceTextfield = UITextField()
        
        let priceAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        priceAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) in
            //                        print("Cancel Selected")
        }))
        
        priceAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction ) in

            let itemUnitPrice = (priceTextfield.text! as NSString).floatValue
            
            do{
                try self.realm.write {
                    record[0].unitPrice = true
                    record[0].itemUnitPrice = itemUnitPrice
                    
                    //Look for cost entry records and update costEntry.itemSpend = item.itemUnitPrice
                    let itemName = record[0].itemName
            
    // Could not get the predicate filter to work with an integer test and therefore used if statement below
    //let predicate = NSPredicate(format: "itemName == [c]%@", "itemNumber == %d", itemName, 1)
                    
                    let predicate = NSPredicate(format: "itemName == [c]%@", itemName)
                    let itemsWithSpend = self.costItems?.filter(predicate)
                    
                    if itemsWithSpend?.count ?? 0 > 0 {
                        for n in 0...(itemsWithSpend!.count-1) {
                            // Update all items with Unit Price
                            itemsWithSpend![n].itemSpend = itemUnitPrice
                        }
                    } // end if
                } // end try
            } catch {
                print("Error updating item record, \(error)")
            }
            self.updateDinersSpend()
            self.updateMenuItemSpend()
            self.loadTables()
            
        })) // end action
        
        priceAlert.addTextField(configurationHandler: { (alertTextField) in
            alertTextField.placeholder = "Unit Price"
            priceTextfield = alertTextField
            priceTextfield.keyboardType = .decimalPad
            
        })
        
        self.present(priceAlert, animated: true, completion: nil )
        
    } // end func

    
    //MARK:---------------------- IB ACTIONS ----------------------------------
    
    @IBAction func addPerson(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add Splitter", message: "Who else is splitting the bill?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // Do Nothing
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if textField.text!.isEmpty {
                    //do nothing
                }
                else {
    
                    let invalidEntry = self.checkForDuplicatePerson(name: textField.text!)
    
                    if invalidEntry == false {
                        let newItem = Person()
                        newItem.personName = textField.text!
                        newItem.personSpend = 0.00
    
                        self.saveNewPerson(name: newItem)
                        self.addCostEntryRecords(person: newItem.personName)
                        self.splitterTableView.reloadData()
                    } //end if
                    else {
    
                        let duplicateAlert = UIAlertController(title: "Duplicate Splitter", message: "Using the same name will be very confusing!", preferredStyle: UIAlertController.Style.alert)
    
                        duplicateAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(duplicateAlert, animated: true, completion: nil)
    
                    } // end else
                } //end else
        }))
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Splitters Name" // Creates initial grey text to be overwritten
            textField = alertTextField
        } // end closure
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addItem(_ sender: UIBarButtonItem) {
       
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add Menu Item", message: "What food & drink is being ordered", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // Do Nothing
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            if textField.text!.isEmpty {
                    // do nothing
                }
                else {
    
                    let invalidEntry = self.checkForDuplicateItem(name: textField.text!)
    
                    if invalidEntry == false {
                        let newItem = Item()
                        newItem.itemName = textField.text!
                        newItem.itemNumber = 0
                        newItem.unitPrice = false
                        newItem.itemUnitPrice = 0.0
                        newItem.itemSpendNet = 0.0
                        // Append not requited as the Results object is auto updating
    
                        self.saveFoodItems(menuItem: newItem)
                        self.addCostEntryRecords(food: newItem.itemName)
                        self.loadTables() // Not sure if this is needed //
                    } // end if
                    else {
    
                        let duplicateAlert = UIAlertController(title: "Duplicate Menu Item", message: "Menu Items names must be different", preferredStyle: UIAlertController.Style.alert)
                        duplicateAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(duplicateAlert, animated: true, completion: nil)
                    }
                } // end else
        }))
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Food & Drink"
            textField = alertTextField
        }
        
        present(alert, animated: true, completion: nil)
    }
    
        
    // MARK:------------------ FUNCTIONS -------------------------------

    func loadTables() {
        
        item = realm.objects(Item.self)
        person = realm.objects(Person.self)
        costItems = realm.objects(CostEntry.self)
        settings = realm.objects(Settings.self)
        
        person = person!.sorted(byKeyPath: "personName")
        item = item!.sorted(byKeyPath: "itemName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        roundingOn = settings?[0].roundingOn ?? false
        percentageTip = settings?[0].gratuity ?? 0.0
        screenHeight = settings?[0].screenHeight ?? 0
        
        splitterTableView.reloadData()
        foodTableView.reloadData()
        
    } // end func
    
    func setAppearance(){
        
        var tableRowHeight: CGFloat
        
        switch screenHeight {
        case 1136:
            fontSize = 15; tableRowHeight = 26
        case 1334:
            fontSize = 18; tableRowHeight = 35
        default:
            fontSize = 20; tableRowHeight = 40
        }
        
        splitterText.font = splitterText.font?.withSize(fontSize)
        foodText.font = foodText.font?.withSize(fontSize)
        
        splitterTableView.separatorColor = UIColor.clear
        splitterTableView.rowHeight = tableRowHeight
        
        foodTableView.separatorColor = UIColor.clear
        foodTableView.rowHeight = tableRowHeight
        
        splitterText.layer.cornerRadius = 10.0
        splitterText.layer.borderColor = orangeColour.cgColor
        splitterText.layer.borderWidth = 1.0
        
        foodText.layer.cornerRadius = 10.0
        foodText.layer.borderColor = orangeColour.cgColor
        foodText.layer.borderWidth = 1.0
        
        let leftButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backTapped))
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: regularFont, size: fontSize)!], for: UIControl.State.normal)
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: mediumFont, size: fontSize)!], for: UIControl.State.selected)
        navigationItem.leftBarButtonItem = leftButton
        
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
    
    func checkForDuplicatePerson (name : String) -> Bool {
        
        var isDuplicate = false
        
        let checkTable = person?.filter("personName == [c]%@", name)
        let recordNumber = checkTable?.count
        
        if recordNumber! > 0 {
            isDuplicate = true
        }
        return isDuplicate
    } // end func
        
    func checkForDuplicateItem (name : String) -> Bool {
        
        var isDuplicate = false
        
        let checkTable = item?.filter("itemName == [c]%@", name)
        let recordNumber = checkTable?.count
        
        if recordNumber! > 0 {
            isDuplicate = true
        }
        return isDuplicate
    } // end func
        
    
    func saveNewPerson(name: Person) {
        
        do{
            try realm.write {
                realm.add(name)
            }
        } catch {
            print("Error saving to Realm, \(error)")
        } // end catch
        
        splitterTableView.reloadData()
    } // end func
    
        
    func saveFoodItems(menuItem: Item) {
        do{
            try realm.write {
                realm.add(menuItem)
            }
        } catch {
            print("Error saving context, \(error)")
        }
        
        foodTableView.reloadData()
    }
    
    func addCostEntryRecords(person: String) {
        
        let nunberOfMenuItems = item?.count ?? 0
        var newCostEntryName : String = ""
        
        if (nunberOfMenuItems) > 0 {
            
            for index in 1...nunberOfMenuItems {
                newCostEntryName = item?[index-1].itemName ?? "No Type"
                
                newCostEntry.personName = person
                newCostEntry.itemName = newCostEntryName
                newCostEntry.itemSpend = 0.0
                
                do{
                    try realm.write {
                        realm.add(newCostEntry)
                        newCostEntry = CostEntry()
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
            } // end for
        } // end if
    } // end func
    
    func addCostEntryRecords(food: String) {
        
        let nunberOfDiners = person?.count ?? 0
        var newCostEntryName : String = ""
        
        if (nunberOfDiners) > 0 {
            
            for index in 1...nunberOfDiners {
                newCostEntryName = person?[index-1].personName ?? "No Name"
                
                newCostEntry.personName = newCostEntryName
                newCostEntry.itemName = food
                newCostEntry.itemSpend = 0.0
                
                do{
                    try realm.write {
                        realm.add(newCostEntry)
                        newCostEntry = CostEntry()
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
            } // end for
        } // end if
    } // end func
    
    func updateMenuItemSpend() {
        
        let numberOfMenuItems = (item?.count)!
        
        if numberOfMenuItems > 0 {
            
            for n in 0...(numberOfMenuItems - 1) {
                let costEntryReords = costItems?.filter("itemName == %@", item![n].itemName)
                let numberOfCostRecords = costEntryReords?.count ?? 0
                var menuItemSpend: Float = 0.0
                
                if numberOfCostRecords > 0 {
                    for m in 0...(numberOfCostRecords - 1) {
                        menuItemSpend = menuItemSpend + (costEntryReords![m].itemSpend * Float(costEntryReords![m].itemNumber))
                    }
                    
                } // end if
                
                do{
                    try realm.write {
                        item![n].itemSpendNet = menuItemSpend
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
                
            } // end for
        } // end if
    } // end func
    
    func updateDinersSpend() {
        
        let numberOfDiners = (person?.count)!
        
        if numberOfDiners > 0 {
            
            for n in 0...(numberOfDiners - 1) {
                let costEntryReords = costItems?.filter("personName == %@", person![n].personName)
                let numberOfCostRecords = costEntryReords?.count ?? 0
                var dinersSpend: Float = 0.0
                
                if numberOfCostRecords > 0 {
                    for m in 0...(numberOfCostRecords - 1) {
                        dinersSpend = dinersSpend + (costEntryReords![m].itemSpend * Float(costEntryReords![m].itemNumber))
                    }
                    
                } // end if
                
                do{
                    try realm.write {
                        person![n].personSpend = dinersSpend
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
                
            } // end for
        } // end if
    } // end func
}
