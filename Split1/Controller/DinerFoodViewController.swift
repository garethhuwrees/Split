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
//    var iphoneType: String = ""
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
        
        self.title = "The Table"
        
        splitterTableView.delegate = self
        splitterTableView.dataSource = self
        splitterTableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        foodTableView.delegate = self
        foodTableView.dataSource = self
        foodTableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
            
            // Set font type and colour
            cell.leftCellLabel.textColor = self.greyColour
            cell.leftCellLabel.font = tableTextFont
            cell.rightCellLabel.textColor = self.greyColour
            cell.rightCellLabel.font = tableTextFont
            
            var spend = (person?[indexPath.row].personSpend) ?? 0.0
            spend = (spend * 100).rounded() / 100
            let spendString = formatNumber(numberToFormat: spend, digits: 2)
            
            cell.leftCellLabel.text = person?[indexPath.row].personName
            cell.rightCellLabel.text = currencyPrefix + spendString
            
            return cell
        }
        
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
            
            // Set font type and colour
            cell.leftCellLabel.textColor = self.greyColour
            cell.leftCellLabel.font = tableTextFont
            cell.rightCellLabel.textColor = self.greyColour
            cell.rightCellLabel.font = tableTextFont
            
            var spend = item?[indexPath.row].itemSpendNet ?? 0.0
            spend = (spend * 100).rounded() / 100
            let spendString = formatNumber(numberToFormat: spend, digits: 2)
            
            cell.leftCellLabel.text = item?[indexPath.row].itemName ?? "No Menu Items Added"
            cell.rightCellLabel.text = currencyPrefix + spendString
            
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
        
    
    // MARK:-------------- DELETE TABLE ENTRY --------------------------
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
        
            if tableView.tag == 1 {
                
                print("Deleting Person")
            
                //Find & Delete Related Cost Entry Records
                if let record = person?[indexPath.row] {
                    do {
                        try realm.write {
                            let recordsToDelete = costItems?.filter("personName == %@", record.personName)
                        
                            let numberOfRecords = recordsToDelete?.count ?? 0
                            
                            if numberOfRecords > 0 {
                                for _ in 0...(numberOfRecords-1) {
                                    var costItemToDelete = recordsToDelete![0]
                                    realm.delete(costItemToDelete)
                                    costItemToDelete = CostEntry()
                                }
                            }
                            else {
                                print("No records to delete")
                            }
                            // Delete Diners Record
                            realm.delete(record)
                            
                        } // end try
                        
                    } catch {
                        print("Error deleting record, \(error)")
                    } // end catch
                } // end if let
                
                loadTables()
                updateMenuItemSpend()
                
            } // end if
        
        } // end if TableView.tag == 1
        
        if tableView.tag == 2 {
            
            if editingStyle == .delete {
                
                if let record = item?[indexPath.row] {
                    do {
                        try realm.write {
                            
                            let recordsToDelete = costItems?.filter("itemName == %@", record.itemName)
                            let numberOfRecords = recordsToDelete?.count ?? 0
                            
                            // Delete Cost Entry Records
                            if numberOfRecords > 0 {
                                for _ in 0...(numberOfRecords-1) {
                                    var costItemToDelete = recordsToDelete![0]
                                    realm.delete(costItemToDelete)
                                    costItemToDelete = CostEntry()
                                }
                            }
                            else {
                                print("No records to delete")
                            }
                            // Delete Menu Record
                            realm.delete(record)
                            
                        } // end try
                        
                    } catch {
                        print("Error deleting record, \(error)")
                    } // end catch
                } // end if let
                
                loadTables()
                updateDinersSpend()
                
            } // end if
        } // end if tableView.tag == 2
        
    } // end override function
    
    //MARK:---------------------- IB ACTIONS ----------------------------------
    
    @IBAction func addPerson(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add Splitter", message: "Who else is splitting the bill?", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Splitter", style: .default) { (action) in
            
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
        } // end closure
        
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Splitters Name" // Creates initial grey text to be overwritten
            textField = alertTextField
        } // end closure
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func addItem(_ sender: UIBarButtonItem) {
       
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add Menu Item", message: "What food & drink is being ordered", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            
            if textField.text!.isEmpty {
                // do nothing
            }
            else {
                
                let invalidEntry = self.checkForDuplicateItem(name: textField.text!)
                
                if invalidEntry == false {
                    let newItem = Item()
                    newItem.itemName = textField.text!
                    // Append not requited as the Results object is auto updating
                    
                    self.saveFoodItems(menuItem: newItem)
                    self.addCostEntryRecords(food: newItem.itemName)
                    self.loadTables() // Not sure if this is needed //
                } // end if
                else {
                    
                    let duplicateAlert = UIAlertController(title: "Duplicate Menu Item", message: "Item names must be different", preferredStyle: UIAlertController.Style.alert)
                    duplicateAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(duplicateAlert, animated: true, completion: nil)
                }
            } // end else
        
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Menu Item Type" // Creates initial grey text to be overwritten
            textField = alertTextField
        }
        
        alert.addAction(action)
        
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
            fontSize = 16; tableRowHeight = 28
        case 1334:
            fontSize = 18; tableRowHeight = 30
        default:
            fontSize = 20; tableRowHeight = 32
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
                        menuItemSpend = menuItemSpend + costEntryReords![m].itemSpend
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
                        dinersSpend = dinersSpend + costEntryReords![m].itemSpend
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
