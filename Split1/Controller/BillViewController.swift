//
//  BillViewController.swift
//  SPLIT!
//
//  Created by Gareth Rees on 31/08/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

class BillViewController: UITableViewController {
    
    let realm = try!Realm()
    var costEntry: Results<CostEntry>?
    var person: Results<Person>?
    var item: Results<Item>?
    var settings: Results<Settings>?
    
    var sections: Array<TableSection> = []
    var numberOfSections: Int = 0
    
    var currencyPrefix: String = ""
    var roundingOn: Bool = false
    var screenHeight: Int = 0
    var fontSize: CGFloat = 20
    var totalSpend: Float = 0.0
    var totalSpendAsSrring = ""
    
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let lightgreyColour = UIColor(red: 236/255, green: 240/255, blue: 241/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    
    
    // MARK:--------------------- VIEW DID LOAD ---------------------------------

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Bill"
        
        tableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backTapped))
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeDown.direction = .down
//        swipeDown.numberOfTouchesRequired = 2
//        self.tableView.addGestureRecognizer(swipeDown)
        self.view.addGestureRecognizer(swipeDown)
        

        self.tableView.panGestureRecognizer.maximumNumberOfTouches = 1
    
        loadTables()
        fillSectionArray()
        
        setAppearance()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    // MARK:--------------------------- SEGUE ---------------------------------
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .left {
            backTapped()
        }
        else if gesture.direction == .down {
            print("SWIPE DOWN")
            performSegue(withIdentifier: "gotoGuide", sender: self)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoGuide" {
            let destinationVC = segue.destination as! IntroViewController
            let trans = CATransition()
            trans.type = CATransitionType.reveal
            trans.subtype = CATransitionSubtype.fromBottom
            //trans.timingFunction = ??
            trans.duration = 0.35
            self.navigationController?.view.layer.add(trans, forKey: nil)
            destinationVC.introType = "guideSwipe"
        }
    }
    

    // MARK:------------------------ TABLE METHODS ----------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].foodType
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (2 * fontSize)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = lightgreyColour
        
        let headerLabel = UILabel(frame: CGRect(x: 35, y: (0.5 * fontSize), width:
            tableView.bounds.size.width, height: tableView.bounds.size.height))
        
        headerLabel.font = UIFont(name: mediumFont, size: fontSize) ?? UIFont(name: "Georgia", size: fontSize)!
        headerLabel.textColor = greyColour
        headerLabel.text = self.tableView(self.tableView, titleForHeaderInSection: section)
        headerLabel.sizeToFit()
        headerView.addSubview(headerLabel)
        
        return headerView
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        var tableRows: Int = 0
        if numberOfSections > 0 {
            for n in 0...(numberOfSections - 1) {
                if section == n {
                    tableRows = sections[n].nameArray.count
                }
            }
        }
        return tableRows
    } // end func
    


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        

        let cell = tableView.dequeueReusableCell(withIdentifier: "quantityTableCell", for: indexPath) as! QuantityTableCell
        
        let tableTextFont: UIFont = UIFont(name: regularFont, size: fontSize) ?? UIFont(name: "Georgia", size: fontSize)!
        
        cell.nameLabel.textColor = self.greyColour
        cell.nameLabel.font = tableTextFont
        cell.quantityLabel.textColor = self.greyColour
        cell.quantityLabel.font = tableTextFont
        cell.spendLabel.textColor = self.greyColour
        cell.spendLabel.font = tableTextFont
        
        cell.nameLabel.text = sections[indexPath.section].nameArray[indexPath.row]
        cell.quantityLabel.text =  sections[indexPath.section].quantityArray[indexPath.row]
        cell.spendLabel.text = currencyPrefix + sections[indexPath.section].spendArray[indexPath.row]
        
        cell.isUserInteractionEnabled = false

        return cell
    }
    

    // MARK:------------------------- LOCAL FUNCTIONS ---------------------------
    
    func loadTables() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("itemSpend > %@", 0.0 as Float)
        costEntry = costEntry!.sorted(byKeyPath: "personName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        roundingOn = settings?[0].roundingOn ?? false
        screenHeight = settings?[0].screenHeight ?? 0

        var numberOfDigits = 2
        var roundingFactor: Float = 100
        if roundingOn {
            numberOfDigits = 0
            roundingFactor = 1
        }
        totalSpend = settings?[0].totalSpend ?? 0.0
        totalSpend = (totalSpend * roundingFactor).rounded() / roundingFactor
        totalSpendAsSrring = formatNumber(numberToFormat: totalSpend, digits: numberOfDigits)
        
        item = realm.objects(Item.self)

        person = realm.objects(Person.self)

        
//        tableView.reloadData()
    }
    
    func fillSectionArray() {
        
        item = item!.filter("itemTotalSpend > %@", 0.0 as Float)
        item = item!.sorted(byKeyPath: "itemName")
        numberOfSections = item!.count
        
        var nameArray: Array<String> = []
        var quantityArray: Array<String> = []
        var priceArray: Array<String> = []
        
        if numberOfSections > 0 {
            for m in 0...numberOfSections-1 {
                var sectionHeader = item![m].itemName

                var tableEntry = costEntry!.filter("itemName == %@", sectionHeader)
                tableEntry = tableEntry.filter("itemNumber > %@", 0 as Int)
                
                if item![m].unitPrice == true {
                    sectionHeader = sectionHeader + " *"
                }
                
                nameArray = []
                quantityArray = []
                priceArray = []
                
                var numberOfDigits = 2
                var roundingFactor: Float = 100
                if roundingOn {
                    numberOfDigits = 0
                    roundingFactor = 1
                }

                for n in 0...tableEntry.count-1 {
                    
//                    var numberOfDigits = 2
//                    var roundingFactor: Float = 100
//                    if roundingOn {
//                        numberOfDigits = 0
//                        roundingFactor = 1
//                    }
//                    var spend = costEntry?[indexPath.row].itemSpend ?? 0.0
//                    spend = (spend * roundingFactor).rounded() / roundingFactor
//                    let spendString = formatNumber(numberToFormat: spend, digits: numberOfDigits)
                    
                    var spend = tableEntry[n].itemSpend
                    spend = (spend * roundingFactor).rounded() / roundingFactor
                    let spendString = formatNumber(numberToFormat: spend, digits: numberOfDigits)
                    
                    nameArray.append(tableEntry[n].personName)
                    quantityArray.append(("\(tableEntry[n].itemNumber)"))
                    priceArray.append(spendString)
                }
                
                let newSecion = TableSection(food: sectionHeader, person: nameArray, quantity: quantityArray, spend: priceArray)
                
                sections.append(newSecion)
                
            } // end for
            
            
            let totalSpendArray = [totalSpendAsSrring]
            let emptyString = [""]
            let finalSection = TableSection(food: "TOTAL (before tax and tip)", person: emptyString, quantity: emptyString, spend: totalSpendArray)
            
            sections.append(finalSection)
            
        } // end if
        
        numberOfSections = sections.count
        
    } // end func
    
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
        
//        splitterText.font = splitterText.font?.withSize(fontSize)
//        foodText.font = foodText.font?.withSize(fontSize)
//        
        tableView.separatorColor = UIColor.clear
        tableView.rowHeight = tableRowHeight
        
        let leftButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backTapped))
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: regularFont, size: fontSize)!], for: UIControl.State.normal)
        leftButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: mediumFont, size: fontSize)!], for: UIControl.State.selected)
        navigationItem.leftBarButtonItem = leftButton

//        
//        splitterText.layer.cornerRadius = 10.0
//        splitterText.layer.borderColor = orangeColour.cgColor
//        splitterText.layer.borderWidth = 1.0
//        
//        foodText.layer.cornerRadius = 10.0
//        foodText.layer.borderColor = orangeColour.cgColor
//        foodText.layer.borderWidth = 1.0
        
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

}
