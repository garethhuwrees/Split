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

class SplitViewController: UIViewController {
    
    
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
   
    
    var percentageTip: Float = 0.0
    var currencyPrefix: String = ""
    var iphoneType: String = ""

    @IBOutlet weak var showTotalBill: UITextField!
    @IBOutlet weak var showTip: UIButton!
    @IBOutlet weak var showBillWithTip: UITextField!
    @IBOutlet weak var showCurrency: UIBarButtonItem!
    @IBOutlet weak var messageText: UITextField!
    @IBOutlet weak var totalBillText: UILabel!
    @IBOutlet weak var gratuityText: UILabel!
    @IBOutlet weak var totalToPayText: UILabel!
    @IBOutlet weak var selectSplitterText: UIButton!
    @IBOutlet weak var selectMenuText: UIButton!
    @IBOutlet weak var selectResetText: UIButton!
    
    
    @IBAction func chooseTipButton(_ sender: Any) {
        tipDropdown.show()
    }
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        resetDropdown.show()
    }
    
    @IBAction func selectCurrency(_ sender: UIBarButtonItem) {
        currencyDropDown.show()
    }
    
    //---------------VIEW DID LOAD & APPEAR ----------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadTables()
        
        checkDeviceType()
        
        setTextSize()
        
        setButtonStyle()
        
        //initialised to 0 so must be reset before further function calls
        //TODO: Can this move to loadTables()?
        percentageTip = settings?[0].gratuity ?? 0.0
        
        showBillTotals()
        
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
        
        
        //MARK:------------- NAVIGATION BAR APPEARANCE -----------------
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
    }

    
    //-------------------- PERFORM SEQUE ----------------------
    
    @IBAction func dinersSelected(_ sender: UIButton) {
        
        performSegue(withIdentifier: "goToDiners", sender: self)
    }
    
    
    @IBAction func foodSelected(_ sender: UIButton) {
        
        performSegue(withIdentifier: "goToFood", sender: self)
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
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .right {
            //print("Swipe Right")
            performSegue(withIdentifier: "goToFood", sender: self)
        }
        
        else if gesture.direction == .left {
            //print("Swipe Left")
            performSegue(withIdentifier: "goToDiners", sender: self)
        }
        else if gesture.direction == .up {
            
        }
        else if gesture.direction == .down {
            
        }
    }
    
    
    // MARK:------------ LOCAL FUNCTIONS -----------------------
    
    
    func loadTables() {
        
        settings = realm.objects(Settings.self)
        
        let numberOfRows = settings?.count
        
        if numberOfRows == 0 {
            
            showCurrency.title = "Currency"
            
            print("Initialising Settings")
            let initialSetting = Settings()
            initialSetting.totalBill = 0.0
            initialSetting.billWithGratuity = 0.0
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
            print("Settings Already Set")
            showCurrency.title = settings?[0].currencySymbol
            iphoneType = settings?[0].phoneType ?? ""
            if iphoneType == "" {
                checkDeviceType()
            }
        }
       
    } // end func
    
    func showBillTotals() {
        
//        setTextSize()
        
        let currencySetting = settings![0].currencySymbol
        if currencySetting == "Currency" {
            currencyPrefix = ""
        }
        else {
            currencyPrefix = String(currencySetting.prefix(3)) // First 3 characters of the string
            let cs = CharacterSet.init(charactersIn: " -")
            currencyPrefix = currencyPrefix.trimmingCharacters(in: cs) // removes the trailing characters
        }

        let billTotal = settings?[0].totalBill ?? 0.0
        let roundedBillTotal = (billTotal * 100).rounded() / 100
        
        var displayedNumber = formatNumber(numberToFormat: roundedBillTotal, digits: 2)
        
        if currencyPrefix == "" {
            showTotalBill.text = displayedNumber
        }
        else {
            showTotalBill.text = currencyPrefix + displayedNumber
        }
        
        let billwithTip = settings?[0].billWithGratuity ?? 0.0
        let roundedBillWithTip = (billwithTip * 100).rounded() / 100
        
        displayedNumber = formatNumber(numberToFormat: roundedBillWithTip, digits: 2)
        
        if currencyPrefix == "" {
            showBillWithTip.text = displayedNumber
        }
        else {
            showBillWithTip.text = currencyPrefix + displayedNumber
        }
        
        let selectedTip = settings?[0].gratuity ?? 0.0
        let displayedTip = formatNumber(numberToFormat: selectedTip, digits: 0)
        showTip.setTitle(displayedTip + "%", for: .normal)
        
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
    func setTextSize() {
        
        var textHeight: CGFloat = 0.0
        
        switch iphoneType {
        case "5,SE":
            textHeight = 16
        case "6,7,8":
            textHeight = 20
        default:
            textHeight = 22
        }
        
        messageText.font = messageText.font?.withSize(textHeight-4)
        totalBillText.font = totalBillText.font.withSize(textHeight)
        gratuityText.font = gratuityText.font.withSize(textHeight)
        totalToPayText.font = totalToPayText.font.withSize(textHeight)
        showTotalBill.font = showTotalBill.font?.withSize(textHeight)
        showBillWithTip.font = showBillWithTip.font?.withSize(textHeight)
        showTip.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight)
        selectSplitterText.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight+6)
        selectMenuText.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight+6)
        selectResetText.titleLabel?.font = UIFont(name: "Chalkboard SE", size: textHeight+2)
        
        messageText.text = ""
        
    }
    
    func setButtonStyle() {
        
        let width: CGFloat = 2.0
        let radius: CGFloat = 10.0
        
        selectSplitterText.layer.cornerRadius = radius
        selectSplitterText.layer.borderColor = greyColour.cgColor
        selectSplitterText.layer.borderWidth = width
        
        selectMenuText.layer.cornerRadius = radius
        selectMenuText.layer.borderColor = greyColour.cgColor
        selectMenuText.layer.borderWidth = width
        
        selectResetText.layer.cornerRadius = radius
        selectResetText.layer.borderColor = orangeColour.cgColor
        selectResetText.layer.borderWidth = width
        
        
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
        
        person = realm.objects(Person.self)
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
                    settings?[0].totalBill = 0.0
                    settings?[0].billWithGratuity = 0.0
                }
            }
            catch {
                print("Error updating cost")
            }
        showBillTotals()
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
            self!.showCurrency.title = selectedCurrency
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
            
            self?.updateBillWithTip() // TODO: Move inside function
            
            self?.showBillTotals()
        }
    }
    
    func updateBillWithTip() {
        
        let billTotal = settings?[0].totalBill ?? 0.0
        let billWithTip = billTotal * (1 + percentageTip/100)
        
        do{
            try realm.write {
                settings?[0].gratuity = percentageTip
                settings?[0].billWithGratuity = billWithTip
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

