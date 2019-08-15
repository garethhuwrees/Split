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


enum SpendType {
    case TotalSpend
    case SpendPlusTip
    case FixedSpend
}

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
    var roundedBill: Float = 0.0
    var taxRate: Float = 0.0
    
    var typeOfSpend: SpendType = .TotalSpend
    var typeOfSpendLabel: String = ""
   
    @IBOutlet weak var splitterTableView: UITableView!
    
    @IBOutlet weak var totalBillText: UILabel!
    @IBOutlet weak var totalToPayText: UILabel!
    @IBOutlet weak var roundedBillText: UILabel!
    
    @IBOutlet weak var showTotalBill: UITextField!
    @IBOutlet weak var showBillWithTip: UITextField!
    @IBOutlet weak var showRoundedBill: UIButton!
    //@IBOutlet weak var showRoundedBill: UITextField!
    
    
    @IBOutlet weak var gratuityText: UILabel!
    @IBOutlet weak var taxRateText: UILabel!
    //@IBOutlet weak var setRoundingText: UILabel!
    @IBOutlet weak var showSplitterName: UILabel!
    
    @IBOutlet weak var showTip: UIButton!
    @IBOutlet weak var showTax: UIButton!
    
    
//    @IBOutlet weak var showCurrency: UIButton!
//    @IBOutlet weak var showRounding: UIButton!
    @IBOutlet weak var showSpendType: UIButton!
    
    @IBOutlet weak var frameTop: UILabel!
    @IBOutlet weak var frameMiddle: UILabel!
    @IBOutlet weak var frameBotton: UILabel!
    
    @IBAction func setRoundedBill(_ sender: Any) {

        var textField = UITextField()
        
        let alert = UIAlertController(title: "Amount To Pay", message: "This muust be greater that the bill", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Enter", style: .default) { (action) in
            
            //TODO:- check when writing to database (as defined or only at end)
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                self.roundedBill = (textField.text! as NSString).floatValue
                
                if let item = self.settings?[0] {
                    do {
                        try self.realm.write {
                            item.billRounded = self.roundedBill
                        }
                    }
                    catch {
                        print("Error updating cost")
                    }
                } // end if
                
                self.showBillTotals()
                self.splitterTableView.reloadData()
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
    
    @IBAction func setTaxRate(_ sender: Any) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Rate of Tax", message: "Enter the local tax rate", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Enter", style: .default) { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                self.taxRate = (textField.text! as NSString).floatValue
            }
                
            self.showBillTotals()
            self.splitterTableView.reloadData()
            
        }
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.taxRate)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end alert
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func selectCurrency(_ sender: UIBarButtonItem) {
        currencyDropDown.show()
    }
    
    @IBAction func selectRounding(_ sender: UIBarButtonItem) {
        roundingOn = !roundingOn
        showBillTotals()
        splitterTableView.reloadData()
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetDropdown.show()
    }
    
    @IBAction func selectSpendType(_ sender: Any) {
        if typeOfSpend == .TotalSpend {
            typeOfSpend = .SpendPlusTip
            typeOfSpendLabel = "Spend + Tip"
        }
        else if typeOfSpend == .SpendPlusTip {
            typeOfSpend = .FixedSpend
            typeOfSpendLabel = "Fixed Amount"
        }
        else if typeOfSpend == .FixedSpend {
            typeOfSpend = .TotalSpend
            typeOfSpendLabel = "Spend (inc Tax)"
        }
        showSpendType.setTitle(typeOfSpendLabel, for: .normal)
        splitterTableView.reloadData()
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
        
        applyUISettings()
        
        applyUISettings()
        
        applyNavbarSettings()
        
//        printFontss()
        
        
        //initialised to 0 so must be reset before further function calls
        //TODO: Can this move to loadTables()?
        percentageTip = settings?[0].gratuity ?? 0.0
        
        showBillTotals()
        splitterTableView.reloadData()
        
        setupTipDropdown()
        setupResetDropdown()
        setupCurrencyDropdown()

        showTotalBill.isUserInteractionEnabled = false
        showBillWithTip.isUserInteractionEnabled = false
//        setRoundingText.isUserInteractionEnabled = false
        
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
            if iphoneType == "5,SE" {
                performSegue(withIdentifier: "goToDiners", sender: self)
            }
            else {
                performSegue(withIdentifier: "gotoTable", sender: self)
            }
        }
        else if gesture.direction == .up {
            performSegue(withIdentifier: "gotoTable", sender: self)
            
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
        
        let percentOfBill = (person?[indexPath.row].percentOfBill) ?? 0.0
        var spend = (person?[indexPath.row].personSpendNet) ?? 0.0
        spend = (spend * 100).rounded() / 100
        let taxAmount = spend * taxRate / 100
        let tipAmount = spend * percentageTip / 100
        
        
        cell.leftCellLabel.textColor = self.greyColour
        cell.leftCellLabel.font = self.tableTextFont
        cell.leftCellLabel.text = person?[indexPath.row].personName
        cell.rightCellLabel.font = self.tableTextFont
        cell.rightCellLabel.textColor = greyColour
        
        if typeOfSpend == .TotalSpend {
            spend = spend + taxAmount
        }
        if typeOfSpend == .SpendPlusTip {
            spend = spend + taxAmount + tipAmount
        }
        if typeOfSpend == .FixedSpend {
            spend = roundedBill * percentOfBill
            
            if roundedBill < (billTotal * (1 + taxRate / 100)) {
                cell.rightCellLabel.textColor = orangeColour
            }
            else {
                cell.rightCellLabel.textColor = greyColour
            }
            
        }
        var numberOfDigits = 2
        var roundingFactor: Float = 100
        if roundingOn {
            numberOfDigits = 0
            roundingFactor = 1
        }
        
        spend = (spend * roundingFactor).rounded() / roundingFactor
        let spendString = formatNumber(numberToFormat: spend, digits: numberOfDigits)
        cell.rightCellLabel.text = self.currencyPrefix + spendString
        

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
            
//            showCurrency.setTitle("Currency", for: .normal)
            
            print("Initialising Settings")
            let initialSetting = Settings()
            initialSetting.billTotalSpend = 0.0
            initialSetting.billWithTip = 0.0
            initialSetting.gratuity = 0.0
            initialSetting.currencySymbol = "None"
            initialSetting.phoneType = ""
            initialSetting.taxRate = 0.0
            initialSetting.spendType = "TotalSpend"
            
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
//            showCurrency.setTitle(settings?[0].currencySymbol, for: .normal)
            iphoneType = settings?[0].phoneType ?? ""
            billTotal = settings?[0].billTotalSpend ?? 0.0
            roundedBill = settings?[0].billRounded ?? 0/0
            //billWithTip = settings?[0].billWithTip ?? 0.0
            percentageTip = settings?[0].gratuity ?? 0.0
            roundingOn = settings?[0].roundingOn ?? false
            taxRate = settings?[0].taxRate ?? 0.0
            
            
            switch settings?[0].spendType {
                case "TotalSpend" : typeOfSpend = .TotalSpend; typeOfSpendLabel = "Spend (inc Tax)"
                case "SpendPlusTip" : typeOfSpend = .SpendPlusTip; typeOfSpendLabel = "Spend + Tip"
                case "FixedSpend" : typeOfSpend = .FixedSpend; typeOfSpendLabel = "Fixed Amount"
                default: typeOfSpend = .TotalSpend
            }
            
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
        if currencySetting == "None" {
            currencyPrefix = ""
        }
        else {
            currencyPrefix = String(currencySetting.prefix(3)) // First 3 characters of the string
            let cs = CharacterSet.init(charactersIn: " -")
            currencyPrefix = currencyPrefix.trimmingCharacters(in: cs) // removes the trailing characters
        }
        
        //TOTAL BILL (INC TAX)
        let billTotal = settings?[0].billTotalSpend ?? 0.0
        let taxAmount = billTotal * taxRate / 100
        let roundedBillTotal = ((billTotal + taxAmount) * roundingFactor).rounded() / roundingFactor
        
        var displayedNumber = formatNumber(numberToFormat: roundedBillTotal, digits: numberOfDigits)
        
        if currencyPrefix == "" {
            showTotalBill.text = displayedNumber
        }
        else {
            showTotalBill.text = currencyPrefix + displayedNumber
        }
        
        //BILL WITH TIP
        let tipAmount = billTotal * percentageTip / 100
        let roundedBillWithTip = ((billTotal + taxAmount + tipAmount) * roundingFactor).rounded() / roundingFactor
        
        displayedNumber = formatNumber(numberToFormat: roundedBillWithTip, digits: numberOfDigits)
        
        if currencyPrefix == "" {
            showBillWithTip.text = displayedNumber
        }
        else {
            showBillWithTip.text = currencyPrefix + displayedNumber
        }
        
        // FIXED AMOUNT
        let roundedBillRounded = (roundedBill * roundingFactor).rounded() / roundingFactor
        displayedNumber = formatNumber(numberToFormat: roundedBillRounded, digits: numberOfDigits)
        
        if roundedBill < (billTotal + taxAmount) {
            showRoundedBill.setTitleColor(orangeColour, for: .normal)
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
        
        
       // TAX RATE & PERCENTAGE TIP
        percentageTip = (percentageTip * 10).rounded() / 10
        let displayedTip = formatNumber(numberToFormat: percentageTip, digits: 0)
        showTip.setTitle(displayedTip + "%", for: .normal)
        
        taxRate = (taxRate * 10).rounded() / 10
        let displayedTax = formatNumber(numberToFormat: taxRate, digits: 0)
        showTax.setTitle(displayedTax + "%", for: .normal)
        
        
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
    
    func applyNavbarSettings() {
        
        var textHeight: CGFloat = 0.0
        
        switch iphoneType {
        case "5,SE":
            textHeight = 16
        case "6,7,8":
            textHeight = 20
        default:
            textHeight = 22
        }
        navigationController?.navigationBar.barTintColor = greenColour
        navigationController?.navigationBar.tintColor = UIColor.white
        //TODO - How to set navigation text font?
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: greyColour]
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "Chalkboard SE", size: textHeight)!]
    }
    
    func applyUISettings() {
        
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
 
//        totalBillText.font = totalBillText.font.withSize(textHeight)
        totalBillText.font = UIFont(name: "ConcertOne-Regular", size: textHeight)
        totalToPayText.font = totalToPayText.font.withSize(textHeight)
        roundedBillText.font = roundedBillText.font.withSize(textHeight)
        
        showTip.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        showTax.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
//        showRounding.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        
        gratuityText.font = gratuityText.font.withSize(textHeight-3)
        taxRateText.font = taxRateText.font.withSize(textHeight-3)
        //setRoundingText.font = setRoundingText.font.withSize(textHeight-3)
        
        
        showSplitterName.font = showSplitterName.font.withSize(textHeight-3)
        showSpendType.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight-3)
        showSpendType.setTitle(settings?[0].spendType, for: .normal)
        
        frameTop.layer.cornerRadius = 10.0
        frameTop.layer.borderColor = orangeColour.cgColor
        frameTop.layer.borderWidth = 0.5
        
        frameMiddle.layer.cornerRadius = 10.0
        frameMiddle.layer.borderColor = orangeColour.cgColor
        frameMiddle.layer.borderWidth = 0.5
        
        frameBotton.layer.cornerRadius = 10.0
        frameBotton.layer.borderColor = orangeColour.cgColor
        frameBotton.layer.borderWidth = 0.5
        
        
    }
    
    func updateSettings() {
        
        var spendType = ""
        switch typeOfSpend {
        case .TotalSpend : spendType = "TotalSpend"
        case .SpendPlusTip : spendType = "SpendPlusTip"
        case .FixedSpend : spendType = "FixedSpend"
         }
        
        
        do{
            try realm.write {
                settings?[0].gratuity = percentageTip
                settings?[0].roundingOn = roundingOn
                settings?[0].billWithTip = billWithTip
                settings?[0].taxRate = taxRate
                settings?[0].spendType = spendType
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
        roundedBill = 0.0
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
        currencyDropDown.dataSource = ["$ - Dollar", "€ - Euro", "£ - Pound", "¥ - Yen/Yuan", "kr - Krona", "CHF - Franc", "Ft - Florint", "R - Rand", "R$ - Real", "None"]
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
                selectedCurrency = "None"
                self!.currencyPrefix = ""
            }
//            self!.showCurrency.setTitle(selectedCurrency, for: .normal)
            do{
                try self!.realm.write {
                    self!.settings?[0].currencySymbol = selectedCurrency
                    self!.settings?[0].currencyPrefix = self!.currencyPrefix
                }
            } catch {
                print("Error saving settings, \(error)")
            }
            
            self!.showBillTotals()
            self!.splitterTableView.reloadData()
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
    
    func printFontss() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }

}

