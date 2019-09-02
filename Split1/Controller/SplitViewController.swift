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
    
    let tipDropdown = DropDown()
    let resetDropdown = DropDown()
    let currencyDropDown = DropDown()
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    let lightGreyColour = UIColor(red: 149/255, green: 165/255, blue: 166/255, alpha: 1)
    
    var fontSize: CGFloat = 22
    let splitFont: String = "Lemon-Regular"
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
   
    // Settings
    var percentageTip: Float = 0.0
    var currencyPrefix: String = ""
//    var iphoneType: String = ""
    var screenHeight: Int = 0
    var roundingOn: Bool = false
    var billTotal: Float = 0.0
    var billWithTip: Float = 0.0
    var roundedBill: Float = 0.0
    var taxRate: Float = 0.0
    
    var typeOfSpend: SpendType = .TotalSpend
    var typeOfSpendLabel: String = ""
    var introType: String = "guide"
   
    @IBOutlet weak var splitterTableView: UITableView!
    
    @IBOutlet weak var totalBillText: UILabel!
    @IBOutlet weak var totalToPayText: UILabel!
    @IBOutlet weak var roundedBillText: UILabel!
    
    @IBOutlet weak var showTotalBill: UITextField!
    @IBOutlet weak var showBillWithTip: UITextField!
    @IBOutlet weak var showRoundedBill: UIButton!
    
    @IBOutlet weak var gratuityText: UILabel!
    @IBOutlet weak var taxRateText: UILabel!
  
    @IBOutlet weak var showTip: UIButton!
    @IBOutlet weak var showTax: UIButton!
    
    @IBOutlet weak var showSpendType: UIButton!
    @IBOutlet weak var showSplitterName: UILabel!
    
    @IBOutlet weak var frameTop: UILabel!
    @IBOutlet weak var frameMiddle: UILabel!
    @IBOutlet weak var frameBotton: UILabel!
    
    @IBAction func setRoundedBill(_ sender: Any) {

        var textField = UITextField()
        
        let alert = UIAlertController(title: "Enter Amount To Pay", message: "This muust be greater that the total spend", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // do nothing
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                self.roundedBill = (textField.text! as NSString).floatValue
                
                if let item = self.settings?[0] {
                    do {
                        try self.realm.write {
                            item.fixedSpend = self.roundedBill
                        }
                    }
                    catch {
                        print("Error updating cost")
                    }
                } // end if
                
                self.showBillTotals()
                self.splitterTableView.reloadData()
            }
            
        }))
        
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.settings?[0].fixedSpend ?? 0.0)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end addTextField
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func chooseTipButton(_ sender: Any) {
        tipDropdown.show()
    }
    
    @IBAction func setTaxRate(_ sender: Any) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Set Rate of Tax", message: "Enter the local tax rate", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // do nothing
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                self.taxRate = (textField.text! as NSString).floatValue
            }
            
            self.updateSettings()
            self.showBillTotals()
            self.splitterTableView.reloadData()
        }))
        
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.taxRate)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end addTextField
    
        present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func selectCurrency(_ sender: UIBarButtonItem) {
        currencyDropDown.show()
    }
    
    @IBAction func selectRounding(_ sender: UIBarButtonItem) {
        roundingOn = !roundingOn
        updateSettings()
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
        updateSettings()
        splitterTableView.reloadData()
    }
    
    
//    // To dismiss the keyboard when tapping on the screen
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
        
        setAppearance()
 
        setNavbarAppearance()
        
//        printFonts()
        
        showBillTotals()
        splitterTableView.reloadData()
        
        setupTipDropdown()
        setupResetDropdown()
        setupCurrencyDropdown()

        showTotalBill.isUserInteractionEnabled = false
        showBillWithTip.isUserInteractionEnabled = false
        
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
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        loadTables()
        showBillTotals()
        splitterTableView.reloadData()

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        updateSettings()
    }

    
    //-------------------- PERFORM SEQUE ----------------------
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .right {
            if screenHeight == 1136 {
                performSegue(withIdentifier: "goToFood", sender: self)
            }
            else {
                performSegue(withIdentifier: "gotoBill", sender: self)
            }
        }
            
        else if gesture.direction == .left {
            if screenHeight == 1136 {
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
        
        if let _ = segue.destination as? BillViewController {
            let trans = CATransition()
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromLeft
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
        }
        
        if segue.identifier == "gotoIntro" {
            let destinationVC = segue.destination as! IntroViewController
            let trans = CATransition()
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromLeft
            //trans.timingFunction = ??
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
            destinationVC.introType = introType
        }
        
        if segue.identifier == "gotoGuide" {
            let destinationVC = segue.destination as! IntroViewController
            let trans = CATransition()
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromLeft
            //trans.timingFunction = ??
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
            destinationVC.introType = "guide"
        }
        
    }
    
    
    @IBAction func introSelected(_ sender: UIBarButtonItem) {
        
        introType = "story"
        performSegue(withIdentifier: "gotoIntro", sender: self)
    }
    
    
    @IBAction func guideSelected(_ sender: Any) {
        
        introType = "guide"
        performSegue(withIdentifier: "gotoIntro", sender: self)
        
    }
    
    
    // MARK:------------------ TABLEVIEW METHODS -----------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return person?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tableTextFont: UIFont = UIFont(name: self.regularFont, size: self.fontSize-3) ?? UIFont(name: "Georgia", size: self.fontSize-3)!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "splitTableCell", for: indexPath) as! SplitTableCell
        
        let percentOfBill = (person?[indexPath.row].percentOfBill) ?? 0.0
        var spend = (person?[indexPath.row].personSpend) ?? 0.0
        spend = (spend * 100).rounded() / 100
        let taxAmount = spend * taxRate / 100
        let tipAmount = spend * percentageTip / 100
        
        
        cell.leftCellLabel.textColor = self.greyColour
        cell.leftCellLabel.font = tableTextFont
        cell.leftCellLabel.text = person?[indexPath.row].personName
        cell.rightCellLabel.font = tableTextFont
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
        
        cell.isUserInteractionEnabled = false
        
        return cell
    }
    
    // MARK:------------ LOCAL FUNCTIONS -----------------------
    
    
    func loadTables() {
        
        settings = realm.objects(Settings.self)
        person = realm.objects(Person.self)
        person = person!.sorted(byKeyPath: "personName")
        
        let numberOfRows = settings?.count
        
        if numberOfRows == 0 {
            let initialSetting = Settings()
            initialSetting.totalSpend = 0.0
            initialSetting.gratuity = 0.0
            initialSetting.currencyPrefix = ""
            initialSetting.taxRate = 0.0
            initialSetting.spendType = "TotalSpend"
            initialSetting.screenHeight = 0
            
            do{
                try realm.write {
                    realm.add(initialSetting)
                }
            } catch {
                print("Error saving context, \(error)")
            }
        } // end if
        else {
            billTotal = settings?[0].totalSpend ?? 0.0
            roundedBill = settings?[0].fixedSpend ?? 0/0
            percentageTip = settings?[0].gratuity ?? 0.0
            roundingOn = settings?[0].roundingOn ?? false
            taxRate = settings?[0].taxRate ?? 0.0
            screenHeight = settings?[0].screenHeight ?? 0
            currencyPrefix = settings?[0].currencyPrefix ?? ""
            
            
            switch settings?[0].spendType {
                case "TotalSpend" : typeOfSpend = .TotalSpend; typeOfSpendLabel = "Spend (inc Tax)"
                case "SpendPlusTip" : typeOfSpend = .SpendPlusTip; typeOfSpendLabel = "Spend + Tip"
                case "FixedSpend" : typeOfSpend = .FixedSpend; typeOfSpendLabel = "Fixed Amount"
                default: typeOfSpend = .TotalSpend
            }
            
            billWithTip = billTotal * (1 + percentageTip/100)
            
            if screenHeight == 0 {
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
        
        //TOTAL BILL (INC TAX)
        let billTotal = settings?[0].totalSpend ?? 0.0
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
        screenHeight = Int(UIScreen.main.nativeBounds.height)

        do{
            try realm.write {
                settings?[0].screenHeight = Int(screenHeight)
                settings?[0].iosVersion = iosVersion
            }
        } catch {
            print("Error saving settings, \(error)")
        }
    }
    
    func setNavbarAppearance() {
        
        // Should aim to move this to AppDeligate - did finishlaunching
        
        var textHeight: CGFloat = 0.0
        
        switch screenHeight {
        case 1136:
            textHeight = fontSize-2
        case 1334:
            textHeight = fontSize
        default:
            textHeight = fontSize+2
        }
        navigationController?.navigationBar.barTintColor = greenColour
        navigationController?.navigationBar.tintColor = UIColor.white
//        navigationController?.navigationBar.
        //TODO - How to set navigation text font?
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: greyColour]
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: regularFont, size: textHeight)!]
        
    }
    
    func setAppearance() {

        var tableRowHeight: CGFloat
        
        switch screenHeight {
        case 1136:
            fontSize = fontSize-6; tableRowHeight = 28
        case 1334:
            fontSize = fontSize-2; tableRowHeight = 30
        default:
            tableRowHeight = 32 // Default fontSize (22)
        }
        
        totalBillText.font = UIFont(name: mediumFont, size: fontSize)
        totalToPayText.font = UIFont(name: mediumFont, size: fontSize)
        roundedBillText.font = UIFont(name: mediumFont, size: fontSize)
        
        showTotalBill.font = UIFont(name: mediumFont, size: fontSize)
        showBillWithTip.font = UIFont(name: mediumFont, size: fontSize)
        showRoundedBill.titleLabel?.font = UIFont(name: mediumFont, size: fontSize)
 
        gratuityText.font = UIFont(name: regularFont, size: fontSize-3)
        taxRateText.font = UIFont(name: regularFont, size: fontSize-3)
        
        showTip.titleLabel?.font = UIFont(name: regularFont, size: fontSize-3)
        showTax.titleLabel?.font = UIFont(name: regularFont, size: fontSize-3)
        
        showSplitterName.font = UIFont(name: boldFont, size: fontSize-2)
        showSpendType.titleLabel?.font = UIFont(name: boldFont, size: fontSize-2)
        showSpendType.setTitle(settings?[0].spendType, for: .normal)
        
        frameTop.layer.cornerRadius = 10.0
        frameTop.layer.borderColor = orangeColour.cgColor
        frameTop.layer.borderWidth = 1.0
        
        frameMiddle.layer.cornerRadius = 10.0
        frameMiddle.layer.borderColor = orangeColour.cgColor
        frameMiddle.layer.borderWidth = 0.8
        
        frameBotton.layer.cornerRadius = 10.0
        frameBotton.layer.borderColor = orangeColour.cgColor
        frameBotton.layer.borderWidth = 0.8
        
        splitterTableView.rowHeight = tableRowHeight
        
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
                settings?[0].taxRate = taxRate
                settings?[0].spendType = spendType
                settings?[0].currencyPrefix = currencyPrefix
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
        
        numberOfRecords = (person?.count)!
        if (numberOfRecords > 0) {
            for n in 0...(numberOfRecords - 1) {
                do {
                    try self.realm.write {
                        person?[n].personSpend = 0.0
                        person?[n].percentOfBill = 0.0
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
                    settings?[0].totalSpend = 0.0 // DELETE
//                    settings?[0].billWithTip = 0.0
                    settings?[0].fixedSpend = 0.0
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
        
        currencyDropDown.selectionAction = { [weak self] (index, item) in
            if index <= 8 {
                self!.currencyPrefix = String(item.prefix(3)) // First 3 characters of the string
                let cs = CharacterSet.init(charactersIn: " -")
                self!.currencyPrefix = self!.currencyPrefix.trimmingCharacters(in: cs) // removes any trailing characters
            }
            else {
                self!.currencyPrefix = ""
            }
            
            self!.updateSettings()
            self!.showBillTotals()
            self!.splitterTableView.reloadData()
        }
    } // end func
    
    func setupTipDropdown() {
        
        tipDropdown.dataSource = ["0%","10%","15%","18%","20%","Custom"]
        tipDropdown.width = 150
        
        customiseDropDown()
        
        // Action triggered on selection
        tipDropdown.selectionAction = { [weak self] (index, item) in
            self?.showTip.setTitle(item, for: .normal)
            
            switch index {
            case 0: self?.percentageTip = 0.0; self?.updateSettings()
            case 1: self?.percentageTip = 10.0; self?.updateSettings()
            case 2: self?.percentageTip = 15.0; self?.updateSettings()
            case 3: self?.percentageTip = 18.0; self?.updateSettings()
            case 4: self?.percentageTip = 20.0; self?.updateSettings()
            case 5: self?.setCustomTip()
                
            default:
                self?.percentageTip = 0.0
            }
            
            self?.billWithTip = self!.billTotal * (1 + self!.percentageTip/100)
            
            self?.showBillTotals()
          
        }
    }
    
    func setCustomTip(){
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Set Percentage Tip", message: "The value must be greater than 1%", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // do nothing
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            
            if textField.text!.isEmpty{
                //Do nothing
            }
            else {
                let customTip = (textField.text! as NSString).floatValue
                if customTip > 1 {
                    self.percentageTip = customTip
                    self.updateSettings()
                    self.billWithTip = self.billTotal * (1 + self.percentageTip/100)
                    self.showBillTotals()
                }
            } // end else
        }))
        
        alert.addTextField { (alertTextField) in
            
            alertTextField.placeholder = "\(self.percentageTip)"
            textField = alertTextField
            textField.keyboardType = .decimalPad
        } // end alert
        
        present(alert, animated: true, completion: nil)
        
    }

    
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
                
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (action: UIAlertAction!) in
                    // do nothing
                }))
                
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
                
                self!.present(confirmAlert, animated: true, completion: nil)

            } // end if
            
        } // end action
    } // end func
    
    
    func customiseDropDown() {
        let appearance = DropDown.appearance()
        
        appearance.cellHeight = 60
        appearance.backgroundColor = UIColor(white: 1, alpha: 1)
        appearance.selectionBackgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        //appearance.separatorColor = UIColor(white: 0.7, alpha: 0.8)
        appearance.cornerRadius = 10
        appearance.shadowColor = greenColour

        appearance.shadowOpacity = 0.2
        appearance.shadowRadius = 25
        appearance.animationduration = 0.25
        appearance.textColor = greyColour

        appearance.textFont = UIFont(name: regularFont, size: 18)!
        
        if #available(iOS 11.0, *) {
            appearance.setupMaskedCorners([.layerMaxXMaxYCorner, .layerMinXMaxYCorner])
        }
    }
    
    //MARK:---------------- TEMP FUNCTIONS -----------------------------------
    
    func printFonts() {
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("Family: \(family) Font names: \(names)")
        }
    }

}

