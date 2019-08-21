//
//  DinersViewController.swift
//  Split1
//
//  Created by Gareth Rees on 15/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

class DinersViewController: UITableViewController {
    
    
    let realm = try!Realm()
    
    var costItems: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    var selectedDiner: String = ""
    var newCostEntry: CostEntry = CostEntry()
    var currencyPrefix: String = ""
    
    var percentageTip: Float = 0.0
    
    var showWithTip: Bool = false
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    
    let tableTextFont: UIFont = UIFont(name: "Chalkboard SE", size: 18) ?? UIFont(name: "Georgia", size: 18)!

    
    @IBOutlet weak var showTipStatus: UIBarButtonItem!
    
    @IBAction func tipStatusPressed(_ sender: UIBarButtonItem) {
        
        if showWithTip == true {
            showTipStatus.tintColor = greyColour
            showTipStatus.title = "Split Without Tip"
            showWithTip = false
        }
        else {
            showTipStatus.tintColor = orangeColour
            showTipStatus.title = "Split With Tip"
            showWithTip = true
        }
        
        loadTables()
    }
    
    //MARK: ------------------VIEW DID LOAD & APPEAR -------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Register the .xib file (historically a .nib file)
        tableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SPLIT!", style: .plain, target: self, action: #selector(backTapped))
        
        loadTables()
        
        showTipStatus.title = "Split Without Tip"
        showTipStatus.tintColor = UIColor.black
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
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
        
//        let billWithTip = totalBill * (1 + percentageTip/100)
        
        if let setSpendTotals = settings?[0] {
            do {
                try realm.write {
                    setSpendTotals.totalSpend = totalBill
//                    setSpendTotals.billWithTip = billWithTip
                }
            }
            catch {
            print("Error updating cost")
            }
        } // end if let
        
    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        trans.type = CATransitionType.push
        trans.subtype = CATransitionSubtype.fromLeft
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .right {
            backTapped()
        }
    }

    // MARK:------------------- INITIATE TABLE VIEW ------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return person?.count ?? 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell

        var spend = (person?[indexPath.row].personSpend) ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
        var spendWithTip = spend * (1 + self.percentageTip/100)
        spendWithTip = (spendWithTip * 100).rounded() / 100
        let spendWithTipString = formatNumber(numberToFormat: spendWithTip, digits: 2)
        
        // Set font type and colour
        cell.leftCellLabel.textColor = self.greyColour
        cell.leftCellLabel.font = self.tableTextFont
//        cell.rightCellLabel.textColor = self.tableTextColour
        cell.rightCellLabel.font = self.tableTextFont
        
        cell.leftCellLabel.text = person?[indexPath.row].personName
        
        
        if showWithTip == false {
            cell.rightCellLabel.textColor = self.greyColour
            cell.rightCellLabel.text = self.currencyPrefix + spendString
        }
        else {
            cell.rightCellLabel.textColor = self.orangeColour
            cell.rightCellLabel.text = self.currencyPrefix + spendWithTipString
        }

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
    
    // MARK:-------------- DELETE DINER --------------------------
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
//        editButtonItem.tintColor = UIColor(displayP3Red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
            
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
    } // end if

    loadTables()
        
    updateMenuItemSpend()

    // tableView.reloadData() - Don't think this is needed

    } // end override function
    
    //MARK:---------------------- SEGUE TO COST ENTRY ------------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedDiner = person?[indexPath.row].personName ?? "No Name"
        
        performSegue(withIdentifier: "gotoDinerCostEntry", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoDinerCostEntry" {

            let destinationVC = segue.destination as! DinersCostViewController

            destinationVC.textPassedOver = "\(selectedDiner)"

        }
    }
    
    //MARK:------------------ ADD DINER ----------------------------------
    
        @IBAction func addDinerPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New Splitter", message: "Who else is splitting the bill?", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            
            if textField.text!.isEmpty {
                //do nothing
            }
            else {
                
                let invalidEntry = self.checkForDuplicate(name: textField.text!)
                
                if invalidEntry == false {
                    let newItem = Person()
                    newItem.personName = textField.text!
                    newItem.personSpend = 0.00
                    
                    self.saveNewDiner(name: newItem)
                    self.addCostEntryRecords(diner: newItem.personName)
                    self.tableView.reloadData()
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
            
    } // end IBAction
    
    
    func checkForDuplicate (name : String) -> Bool {
        
        var isDuplicate = false
        
        let checkTable = person?.filter("personName == [c]%@", name)
        let recordNumber = checkTable?.count
        
        if recordNumber! > 0 {
            isDuplicate = true
        }
        return isDuplicate
    } // end func
    
    //MARK: -----------LOCAL FUNCTIONS ---------------------------------

    func loadTables() {
        
        item = realm.objects(Item.self)
        person = realm.objects(Person.self)
        costItems = realm.objects(CostEntry.self)
        settings = realm.objects(Settings.self)
        
        person = person!.sorted(byKeyPath: "personName")
        
        percentageTip = settings?[0].gratuity ?? 0.0
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        tableView.reloadData()
        
    } // end func
    
    func addCostEntryRecords(diner: String) {
        
        let nunberOfMenuItems = item?.count ?? 0
        var newCostEntryName : String = ""
        
        if (nunberOfMenuItems) > 0 {
            
            for index in 1...nunberOfMenuItems {
                newCostEntryName = item?[index-1].itemName ?? "No Type"
                
                newCostEntry.personName = diner
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
    
    
    func saveNewDiner(name: Person) {
        
        do{
            try realm.write {
                realm.add(name)
            }
        } catch {
            print("Error saving to Realm, \(error)")
        } // end catch
        
        tableView.reloadData()
    } // end func
    
//    func printTableCount() {
//
//        let dinerCount = person?.count ?? 0
//        print ("Number of Diners: \(dinerCount)")
//
//        let foodCount = person?.count ?? 0
//        print ("Number of Food Items: \(foodCount)")
//
//        let associateCount = costItems?.count ?? 0
//        print ("Number of Cost Entry Items: \(associateCount)")
//
//    } //end func
    
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
    

}
