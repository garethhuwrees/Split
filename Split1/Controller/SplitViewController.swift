//
//  SplitViewController.swift
//  Split1
//
//  Created by Gareth Rees on 14/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift
import DropDown
// import DeviceCheck // - is this needed?

class SplitViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    let realm = try!Realm()
    
    var costItems: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    // let defaults: UserDefaults = UserDefaults.standard
    
    let tipDropdown = DropDown()
    let resetDropdown = DropDown()
    let currencyDropDown = DropDown()
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    let lightGreyColour = UIColor(red: 149/255, green: 165/255, blue: 166/255, alpha: 1)
    
    let tableTextFont: UIFont = UIFont(name: "Chalkboard SE", size: 18) ?? UIFont(name: "Regular", size: 16)!
   
    // Settings
    var percentageTip: Float = 0.0
    var currencyPrefix: String = ""
    var iphoneType: String = ""
    var roundingOn: Bool = false
    var billTotal: Float = 0.0
    var billWithTip: Float = 0.0

   
    @IBOutlet weak var splitterTableView: UITableView!
    
    @IBOutlet weak var totalBillText: UILabel!
    @IBOutlet weak var totalToPayText: UILabel!
    @IBOutlet weak var roundedBillText: UILabel!
    
    @IBOutlet weak var showTotalBill: UITextField!
    @IBOutlet weak var showBillWithTip: UITextField!
    @IBOutlet weak var showRoundedBill: UIButton!
    //@IBOutlet weak var showRoundedBill: UITextField!
    
    
    @IBOutlet weak var gratuityText: UILabel!
    @IBOutlet weak var setCurrencyText: UILabel!
    @IBOutlet weak var setRoundingText: UILabel!
    
    @IBOutlet weak var showTip: UIButton!
    @IBOutlet weak var showCurrency: UIButton!
    @IBOutlet weak var showRounding: UIButton!
    
    @IBOutlet weak var frameTop: UILabel!
    @IBOutlet weak var frameMiddle: UILabel!
    
    @IBAction func setRoundedBill(_ sender: Any) {

        var textField = UITextField()
        
        let alert = UIAlertController(title: "Amount To Pay", message: "This muust be greater that the bill", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Enter", style: .default) { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                let roundedBill = (textField.text! as NSString).floatValue
                
                if let item = self.settings?[0] {
                    do {
                        try self.realm.write {
                            item.billRounded = roundedBill
                        }
                    }
                    catch {
                        print("Error updating cost")
                    }
                } // end if
                
                self.showBillTotals()
            }
            
        }
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.settings?[0].billRounded ?? 0.0)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end alert
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    

    
    @IBAction func chooseTipButton(_ sender: Any) {
        tipDropdown.show()
    }
    

    @IBAction func selectCurrency(_ sender: Any) {
        currencyDropDown.show()
    }
    
    @IBAction func selectRounding(_ sender: Any) {
        roundingOn = !roundingOn
        
        showBillTotals()
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetDropdown.show()
    }
    
//    // Solution found on stackoverflow to dismiss the keyboard when tapping on the screen
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        view.endEditing(true)
//    }
    
    //MARK: ---------------VIEW DID LOAD & APPEAR ----------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitterTableView.delegate = self
        splitterTableView.dataSource = self
        splitterTableView.register(UINib(nibName: "SplitCustomCell", bundle: nil) , forCellReuseIdentifier: "splitTableCell")
        splitterTableView.separatorColor = UIColor.clear
        splitterTableView.rowHeight = 30
        
        loadTables()
        
        checkDeviceType()
        
        applyUiSettings()
        
        
        //initialised to 0 so must be reset before further function calls
        //TODO: Can this move to loadTables()?
        percentageTip = settings?[0].gratuity ?? 0.0
        
        showBillTotals()
        
        setupTipDropdown()
        setupResetDropdown()
        setupCurrencyDropdown()

        showTotalBill.isUserInteractionEnabled = false
        showBillWithTip.isUserInteractionEnabled = false
        setRoundingText.isUserInteractionEnabled = false
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        
       // Set Navigation Bar Appearance
        // Bar colour
        navigationController?.navigationBar.barTintColor = greenColour
        // Navigation text colour
        navigationController?.navigationBar.tintColor = UIColor.white
        //TODO - How to set navigation text font?
        // Navigation title colour and font
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: greyColour]
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Chalkboard SE", size: 24)!]
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        showBillTotals()
        splitterTableView.reloadData()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        updateSettings()
    }

    
    //-------------------- PERFORM SEQUE ----------------------
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .right {
            performSegue(withIdentifier: "goToFood", sender: self)
        }
            
        else if gesture.direction == .left {
            performSegue(withIdentifier: "goToDiners", sender: self)
        }
        else if gesture.direction == .up {
            
        }
        else if gesture.direction == .down {
            
        }
    }

    
    // Must uncheck 'Animates' on the seque attribites for this to work
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let _ = segue.destination as? FoodViewController {
            let trans = CATransition()
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromLeft
            //trans.timingFunction = ??
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
        }
        if let _ = segue.destination as? DinersViewController {
            let trans = CATransition()
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromRight
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
        }
        
    }
    
    
    @IBAction func introSelected(_ sender: UIBarButtonItem) {
        
        performSegue(withIdentifier: "goToIntro", sender: self)
    }
    
    
    @IBAction func guideSelected(_ sender: Any) {
        
    }
    
    
    // MARK:------------------ TABLEVIEW METHODS -----------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return person?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
        
        var spend = (person?[indexPath.row].personSpendNet) ?? 0.0
        spend = (spend * 100).rounded() / 100
        let spendString = formatNumber(numberToFormat: spend, digits: 2)
        
//        var spendWithTip = spend * (1 + self.percentageTip/100)
//        spendWithTip = (spendWithTip * 100).rounded() / 100
//        let spendWithTipString = formatNumber(numberToFormat: spendWithTip, digits: 2)
        
        // Set font type and colour
        cell.leftCellLabel.textColor = self.greyColour
        cell.leftCellLabel.font = self.tableTextFont
        cell.leftCellLabel.text = person?[indexPath.row].personName
        //        cell.rightCellLabel.textColor = self.tableTextColour
        cell.rightCellLabel.textColor = self.greyColour
        cell.rightCellLabel.font = self.tableTextFont
        cell.rightCellLabel.text = self.currencyPrefix + spendString // replace with if, else if
        
        
//        if showWithTip == false {
//            cell.rightCellLabel.textColor = self.greyColour
//            cell.rightCellLabel.text = self.currencyPrefix + spendString
//        }
//        else {
//            cell.rightCellLabel.textColor = self.orangeColour
//            cell.rightCellLabel.text = self.currencyPrefix + spendWithTipString
//        }
//
        return cell
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 30
//    }
    
    // MARK:------------ LOCAL FUNCTIONS -----------------------
    
    
    func loadTables() {
        
        settings = realm.objects(Settings.self)
        person = realm.objects(Person.self)
        person = person!.sorted(byKeyPath: "personName")
        
        let numberOfRows = settings?.count
        
        if numberOfRows == 0 {
            
            showCurrency.setTitle("Currency", for: .normal)
            
            print("Initialising Settings")
            let initialSetting = Settings()
            initialSetting.billTotalSpend = 0.0
            initialSetting.billWithTip = 0.0
            initialSetting.gratuity = 0.0
            initialSetting.currencySymbol = "Currency"
            initialSetting.phoneType = ""
            
            do{
                try realm.write {
                    realm.add(initialSetting)
                }
            } catch {
                print("Error saving context, \(error)")
            }
            
        } // end if
        else {
            // print("Settings Already Set")
            showCurrency.setTitle(settings?[0].currencySymbol, for: .normal)
            iphoneType = settings?[0].phoneType ?? ""
            billTotal = settings?[0].billTotalSpend ?? 0.0
            //billWithTip = settings?[0].billWithTip ?? 0.0
            percentageTip = settings?[0].gratuity ?? 0.0
            roundingOn = settings?[0].roundingOn ?? false
            
            billWithTip = billTotal * (1 + percentageTip/100)
            
            if iphoneType == "" {
                checkDeviceType()
            }
        }
       
    } // end func
    
    func showBillTotals() {
        
        var numberOfDigits = 2
        var roundingFactor: Float = 100
        if roundingOn == true {
            numberOfDigits = 0
            roundingFactor = 1
        }
        
        let currencySetting = settings![0].currencySymbol
        if currencySetting == "Currency" {
            currencyPrefix = ""
        }
        else {
            currencyPrefix = String(currencySetting.prefix(3)) // First 3 characters of the string
            let cs = CharacterSet.init(charactersIn: " -")
            currencyPrefix = currencyPrefix.trimmingCharacters(in: cs) // removes the trailing characters
        }
        
        //Set Bill Total
        let billTotal = settings?[0].billTotalSpend ?? 0.0
        let roundedBillTotal = (billTotal * roundingFactor).rounded() / roundingFactor
        
        var displayedNumber = formatNumber(numberToFormat: roundedBillTotal, digits: numberOfDigits)
        
        if currencyPrefix == "" {
            showTotalBill.text = displayedNumber
        }
        else {
            showTotalBill.text = currencyPrefix + displayedNumber
        }
        
        //Set Bill With Tip
        billWithTip = billTotal * (1 + percentageTip/100)
        let roundedBillWithTip = (billWithTip * roundingFactor).rounded() / roundingFactor
        
        displayedNumber = formatNumber(numberToFormat: roundedBillWithTip, digits: numberOfDigits)
        
        if currencyPrefix == "" {
            showBillWithTip.text = displayedNumber
        }
        else {
            showBillWithTip.text = currencyPrefix + displayedNumber
        }
        
        // Set Bill Rounded
        let billRounded = settings?[0].billRounded ?? 0.0
        
        let roundedBillRounded = (billRounded * roundingFactor).rounded() / roundingFactor
        
        displayedNumber = formatNumber(numberToFormat: roundedBillRounded, digits: numberOfDigits)
        
        if billRounded < billTotal {
            showRoundedBill.setTitleColor(lightGreyColour, for: .normal)
        }
        else {
            showRoundedBill.setTitleColor(greyColour, for: .normal)
        }
        
        if currencyPrefix == "" {
            showRoundedBill.setTitle(displayedNumber, for: .normal)
        }
        else {
            showRoundedBill.setTitle(currencyPrefix + displayedNumber, for: .normal)
        }
        
        
        //let selectedTip = settings?[0].gratuity ?? 0.0
        let displayedTip = formatNumber(numberToFormat: percentageTip, digits: 0)
        showTip.setTitle(displayedTip + "%", for: .normal)
        
        
        if roundingOn == true {
            showRounding.setTitle("On", for: .normal)
        }
        else {
            showRounding.setTitle("Off", for: .normal)
        }
        
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
    
    func checkDeviceType() {
        
        let iosVersion = UIDevice.current.systemVersion
        let screenHeight = UIScreen.main.nativeBounds.height
        switch screenHeight {
            case 1136: iphoneType = "5,SE"
            case 1334: iphoneType = "6,7,8"
            case 1920, 2208: iphoneType = "6,7,8 plus"
            case 2436: iphoneType = "X,XS"
            case 1792: iphoneType = "XR"
            default: iphoneType = ""
        }

        print("iPhone type: \(iphoneType)")
        do{
            try realm.write {
                settings?[0].phoneType = iphoneType
                settings?[0].screenHeight = Int(screenHeight)
                settings?[0].iosVersion = iosVersion
            }
        } catch {
            print("Error saving settings, \(error)")
        }
    }
    
    //TODO
    func applyUiSettings() {
        
        var textHeight: CGFloat = 0.0
        
        switch iphoneType {
        case "5,SE":
            textHeight = 16
        case "6,7,8":
            textHeight = 20
        default:
            textHeight = 22
        }
        
        showTotalBill.font = showTotalBill.font?.withSize(textHeight)
        showBillWithTip.font = showBillWithTip.font?.withSize(textHeight)
        showRoundedBill.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight)
 
        totalBillText.font = totalBillText.font.withSize(textHeight)
        totalToPayText.font = totalToPayText.font.withSize(textHeight)
        roundedBillText.font = roundedBillText.font.withSize(textHeight)
        
        showTip.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        showCurrency.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        showRounding.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        
        gratuityText.font = gratuityText.font.withSize(textHeight-3)
        setCurrencyText.font = setCurrencyText.font.withSize(textHeight-3)
        setRoundingText.font = setRoundingText.font.withSize(textHeight-3)
        
        frameTop.layer.cornerRadius = 10.0
        frameTop.layer.borderColor = orangeColour.cgColor
        frameTop.layer.borderWidth = 0.5
        
        frameMiddle.layer.cornerRadius = 10.0
        frameMiddle.layer.borderColor = orangeColour.cgColor
        frameMiddle.layer.borderWidth = 0.5
        
    }
    
    func updateSettings() {
        
        do{
            try realm.write {
                settings?[0].gratuity = percentageTip
                settings?[0].roundingOn = roundingOn
                settings?[0].billWithTip = billWithTip
            }
        } catch {
            print("Error saving settings, \(error)")
        }
    }
    
    
    // MARK:-------------- RESET DATA FUNCTIONS --------------
    
    func resetSpend() {
        
        costItems = realm.objects(CostEntry.self)
        var numberOfRecords = (costItems?.count)!
        if (numberOfRecords > 0) {
            for n in 0...(numberOfRecords - 1) {
                do {
                    try self.realm.write {
                        costItems?[n].itemSpend = 0.0
                    }
                }
                catch {
                    print("Error updating cost")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
            }
        
//        person = realm.objects(Person.self) // Moved to Load Tables - can now be deleted??
        numberOfRecords = (person?.count)!
        if (numberOfRecords > 0) {
            for n in 0...(numberOfRecords - 1) {
                do {
                    try self.realm.write {
                        person?[n].personSpendNet = 0.0
                        person?[n].personSpendGross = 0.0
                    }
                }
                catch {
                    print("Error updating cost")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
        }
        
        item = realm.objects(Item.self)
        numberOfRecords = (item?.count)!
        if (numberOfRecords > 0) {
            for n in 0...(numberOfRecords - 1) {
                do {
                    try self.realm.write {
                        item?[n].itemSpendNet = 0.0
                    }
                }
                catch {
                    print("Error updating cost")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
        }
        
        if settings!.count > 0 {
            do {
                try self.realm.write {
                    settings?[0].billTotalSpend = 0.0 // DELETE
                    settings?[0].billWithTip = 0.0
                    settings?[0].billRounded = 0.0
                }
            }
            catch {
                print("Error updating cost")
            }
        billWithTip = 0.0
        showBillTotals()
        splitterTableView.reloadData()
        }
        
    } // end func
    
    func deleteDiners() {
        // diners = realm.objects(Diner.self)
        let numberOfRecords = (person?.count)!
        if (numberOfRecords > 0) {
            for _ in 0...(numberOfRecords - 1) {
                let recordToDelete = person![0]
                do {
                    try self.realm.write {
                        realm.delete(recordToDelete)
                    }
                }
                catch {
                    print("Error deleting record - Diners")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
        }
        
        splitterTableView.reloadData()
    } // end func

    func deleteItems() {
        
        let numberOfRecords = (item?.count)!
        if (numberOfRecords > 0) {
            for _ in 0...(numberOfRecords - 1) {
                let recordToDelete = item![0]
                do {
                    try self.realm.write {
                        realm.delete(recordToDelete)
                    }
                }
                catch {
                    print("Error deleting record - Items")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
        }
    }
    
    func deleteCostEntry() {
        
        let numberOfRecords = (costItems?.count)!
        if (numberOfRecords > 0) {
            for _ in 0...(numberOfRecords - 1) {
                let recordToDelete = costItems![0]
                do {
                    try self.realm.write {
                        realm.delete(recordToDelete)
                    }
                }
                catch {
                    print("Error deleting record - Items")
                }
            } // end for
        } // end if
        else {
            print("No records to delete")
        }
        
    }
    
    // MARK:---------- SET UP DRORDOWNS ---------------------
    
    func setupCurrencyDropdown() {
        currencyDropDown.dataSource = ["$ - Dollar", "€ - Euro", "£ - Pound", "¥ - Yen/Yuan", "kr - Krona", "CHF - Franc", "Ft - Florint", "R - Rand", "R$ - Real", "Null"]
        currencyDropDown.width = 130
        
        customiseDropDown()
        
        var selectedCurrency = ""
        
        currencyDropDown.selectionAction = { [weak self] (index, item) in
            if index <= 8 {
                selectedCurrency = item
                self!.currencyPrefix = String(selectedCurrency.prefix(3)) // First 3 characters of the string
                let cs = CharacterSet.init(charactersIn: " -")
                self!.currencyPrefix = self!.currencyPrefix.trimmingCharacters(in: cs) // removes any trailing characters
            }
            else {
                selectedCurrency = "Currency"
                self!.currencyPrefix = ""
            }
            self!.showCurrency.setTitle(selectedCurrency, for: .normal)
            do{
                try self!.realm.write {
                    self!.settings?[0].currencySymbol = selectedCurrency
                    self!.settings?[0].currencyPrefix = self!.currencyPrefix
                }
            } catch {
                print("Error saving settings, \(error)")
            }
            
            self!.showBillTotals()
        }
    } // end func
    
    func setupTipDropdown() {
        
        tipDropdown.dataSource = ["Select", "0%","10%","15%","18%","20%"]
        tipDropdown.width = 150
        
        customiseDropDown()
        
        // Action triggered on selection
        tipDropdown.selectionAction = { [weak self] (index, item) in
            self?.showTip.setTitle(item, for: .normal)
            
            switch index {
            case 0: self?.percentageTip = 0.0
            case 1: self?.percentageTip = 0.0
            case 2: self?.percentageTip = 10.0
            case 3: self?.percentageTip = 15.0
            case 4: self?.percentageTip = 18.0
            case 5: self?.percentageTip = 20.0
                
            default:
                self?.percentageTip = 0.0
            }
            
            self?.billWithTip = self!.billTotal * (1 + self!.percentageTip/100)
            
            //self?.updateBillWithTip() // DELETE
            
            self?.showBillTotals()
        }
    }
    
    func updateBillWithTip() { // DELETE FUNCTION
        
        let billTotal = settings?[0].billTotalSpend ?? 0.0
        let billWithTip = billTotal * (1 + percentageTip/100)
        
        do{
            try realm.write {
                settings?[0].gratuity = percentageTip
                settings?[0].billWithTip = billWithTip
                settings?[0].roundingOn = roundingOn
            }
        } catch {
            print("Error saving settings, \(error)")
        }
    } // end func
    
    func setupResetDropdown() {
        resetDropdown.dataSource = ["Reset Spend", "Delete Menu Items", "Delete Splitters", "Delete All Data", "CANCEL"]
        resetDropdown.width = 180
        
        customiseDropDown()
        
        resetDropdown.selectionAction = { [weak self] (index, item) in
            
            if index != 4 {
                
            var title = ""
                switch index {
                case 0: title = "Reset Spend?"
                case 1: title = "Delete Menu Items?"
                case 2: title = "Delete Splitters?"
                case 3: title = "Delete All Data?"
                default: title = "Nothing to Delete"
                }
                
                let confirmAlert = UIAlertController(title: title, message: "Click OK to Confirm", preferredStyle: UIAlertController.Style .alert)
                
                confirmAlert.addAction(UIAlertAction(title: "OK", style: .default, handler:{ (action: UIAlertAction!) in
                    switch index {
                    case 0: self!.resetSpend()
                    case 1: self?.resetSpend(); self?.deleteItems(); self?.deleteCostEntry()
                    case 2: self!.resetSpend(); self!.deleteDiners(); self?.deleteCostEntry()
                    case 3: self?.resetSpend(); self?.deleteItems(); self?.deleteDiners();self?.deleteCostEntry()
                        
                    default:
                        print("A case default must have an executable statement")
                    }
                }))
                
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler:{ (action: UIAlertAction!) in
                    print("Don't delete anything")
                }))
                
                self!.present(confirmAlert, animated: true, completion: nil)

            } // end if
            
        } // end action
    } // end func
    
    
    func customiseDropDown() {
        let appearance = DropDown.appearance()
        
        appearance.cellHeight = 60
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 0.6494, green: 0.8155, blue: 1.0, alpha: 0.2)
        //        appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 10
        appearance.shadowColor = UIColor(displayP3Red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
        appearance.shadowOpacity = 0.9
        appearance.shadowRadius = 25
        appearance.animationduration = 0.25
        appearance.textColor = UIColor(displayP3Red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
        appearance.textFont = UIFont(name: "Chalkboard SE", size: 18)!
        
        if #available(iOS 11.0, *) {
            appearance.setupMaskedCorners([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        }
    }

}

