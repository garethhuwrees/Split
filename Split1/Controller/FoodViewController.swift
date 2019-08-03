//
//  FoodViewController.swift
//  Split1
//
//  Created by Gareth Rees on 15/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift


class FoodViewController: UITableViewController {
    
    // Initialise a new Realm (it is OK to ovreride the try/catch for Realm)
    let realm = try!Realm()
    
    // Must change the datatype from an array to a Results object. (all data coming back from Realm is of this type
    // Food items must also be unwrapped (!)
    
    var costItems: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>? // foodItems is an 'optional'
    var settings: Results<Settings>?
    
    var selectedFood: String = ""
    var currencyPrefix: String = ""
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
  
    let tableTextColour: UIColor = UIColor(red: 44/255, green: 62/255, blue: 00/255, alpha: 1)
    let tableTextFont: UIFont = UIFont(name: "Chalkboard SE", size: 18) ?? UIFont(name: "Regular", size: 18)!
    
   
    //Setting up some Global Variables
    //var numberOfDiners: Int = 0
    //var dinerArray: [String] = []
    
    var newCostEntry: CostEntry = CostEntry()
   
    // MARK:------------- VIEW DID LOAD ------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SPLIT!", style: .plain, target: self, action: #selector(backTapped))
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        loadTables()
//        printTableCount()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadTables()
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .left {
            backTapped()
        }

    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        trans.type = CATransitionType.push
        trans.subtype = CATransitionSubtype.fromRight
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }

    // MARK:----------------- VIEW DID DISAPEAR --------------------
    
    override func viewDidDisappear(_ animated: Bool) {
        
        // Update Total Spend (Settings)
        var totalBill: Float = 0.0
        let numberOfDiners = person?.count ?? 0
        //        print("Number of Diners in Table: \(numberOfDiners)")
        
        if numberOfDiners > 0 {
            for n in 0...(numberOfDiners-1) {
                //            print("Diner Spend \(diners![n].dinerNetSpend)")
                totalBill = totalBill + person![n].personSpendNet
            } // end for
        }
        else {
            // leave totalBill = 0.0
        }
        
        let  percentageTip = settings?[0].gratuity ?? 0.0
        let billWithTip = totalBill * (1 + percentageTip/100)
        
        print("The Total Bill is \(totalBill)")
        
        if let setSpendTotals = settings?[0] {
            do {
                //print(setSpendTotals.totalBill)
                try realm.write {
                    setSpendTotals.totalBill = totalBill
                    setSpendTotals.billWithGratuity = billWithTip
                }
            }
            catch {
                print("Error updating cost")
            }
        } // end if let

    }
    
    
    // MARK:----------------------- INITIATE TABLE VIEW -----------------------

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the count of foodItems if not 0, otherwise return 1
        return item?.count ?? 1 // ?? is the 'nil coalesing operator'
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
        
        // Set font type and colour
        cell.leftCellLabel.textColor = self.tableTextColour
        cell.leftCellLabel.font = self.tableTextFont
        cell.rightCellLabel.textColor = self.tableTextColour
        cell.rightCellLabel.font = self.tableTextFont
        
        var spend = item?[indexPath.row].itemSpendNet ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        cell.leftCellLabel.text = item?[indexPath.row].itemName ?? "No Menu Items Added"
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
    
    // MARK:---------------------- SEGUE TO FOOD COST ENTRY ------------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedFood = item?[indexPath.row].itemName ?? "No Name"
        
        print(selectedFood)
        
        performSegue(withIdentifier: "gotoFoodCostEntry", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoFoodCostEntry" {
            
            let destinationVC = segue.destination as! FoodCostViewController
            
            destinationVC.textPassedOver = "\(selectedFood)"
            
        }
    }
    
    
    
    // MARK:---------------------- DELETE FOOD ITEMS -----------------------------
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            if let record = item?[indexPath.row] {
                do {
                    try realm.write {

                        let recordsToDelete = costItems?.filter("itemName == %@", record.itemName)
                        print("Deleting \(record.itemName)")
                        let numberOfRecords = recordsToDelete?.count ?? 0
                        print("There are \(numberOfRecords) record to delete")
                        
                        // Delete Cost Entry Records
                        if numberOfRecords > 0 {
                            for index in 0...(numberOfRecords-1) {
                                var costItemToDelete = recordsToDelete![0]
                                print("Deleting \(index) Record, \(costItemToDelete.personName), \(costItemToDelete.itemName)")
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
            } // end if
        
        loadTables()
        
        updateDinersSpend()

    } // end override func
    
    
    //MARK:--------------------- ADD FOOD ITEMS ----------------------------------

    @IBAction func addFoodPressed(_ sender: UIBarButtonItem) {
        
        //Initialise a variable within scope of the entire IBAction
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Menu Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            
            if textField.text!.isEmpty {
                // do nothing
            }
            else {
                
                let invalidEntry = self.checkForDuplicate(name: textField.text!)
                
                if invalidEntry == false {
                    let newItem = Item()
                    newItem.itemName = textField.text!
                    // Append not requited as the Results object is auto updating
                    
                    self.saveFoodItems(menuItem: newItem)
                    self.addCostEnrtyRecords(food: newItem.itemName)
                    self.loadTables() // Not sure if this is needed //
                } // end if
                else {
    
                    let duplicateAlert = UIAlertController(title: "Duplicate Menu Item", message: "They must be different", preferredStyle: UIAlertController.Style.alert)
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
    
    func checkForDuplicate (name : String) -> Bool {
        
        var isDuplicate = false
        
        let checkTable = item?.filter("itemName == [c]%@", name)
        let recordNumber = checkTable?.count
        
        if recordNumber! > 0 {
            isDuplicate = true
        }
        return isDuplicate
    } // end func
    
    //------------------------- FUNCTIONS ------------------------
    
    func saveFoodItems(menuItem: Item) {
        do{
            try realm.write {
                realm.add(menuItem)
            }
        } catch {
            print("Error saving context, \(error)")
        }
        
        tableView.reloadData()
    }
    
    
    func loadTables() {
    
        item = realm.objects(Item.self)
        person = realm.objects(Person.self)
        costItems = realm.objects(CostEntry.self)
        settings = realm.objects(Settings.self)
        
        item = item!.sorted(byKeyPath: "itemName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        tableView.reloadData()
    }
    
    func addCostEnrtyRecords(food: String) {
        
        let nunberOfDiners = person?.count ?? 0
        var newCostEntryName : String = ""
        
        if (nunberOfDiners) > 0 {
        
            for index in 1...nunberOfDiners {
                print("Index : \(index)")
                newCostEntryName = person?[index-1].personName ?? "No Name"
                
                newCostEntry.personName = newCostEntryName
                newCostEntry.itemName = food
                newCostEntry.itemSpend = 0.0
                
                do{
                    try realm.write {
                        realm.add(newCostEntry)
                        print("Write to \(newCostEntryName)")
                        newCostEntry = CostEntry()
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
            } // end for
            printTableCount()
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
                
                print("\(person![n].personSpendNet) - \(dinersSpend)")
                do{
                    try realm.write {
                        person![n].personSpendNet = dinersSpend
                    }
                } catch {
                    print("Error saving to Realm, \(error)")
                }
                
            } // end for
        } // end if
        
        
        
    } // end func
    
    
    
    func printTableCount() {
        
        let dinerCount = person?.count ?? 0
        print ("Number of Diners: \(dinerCount)")
        
        let foodCount = item?.count ?? 0
        print ("Number of Food Items: \(foodCount)")
        
        let costEntryCount = costItems?.count ?? 0
        print ("Number of Cost Entry Items: \(costEntryCount)")
        
    }
    
}
