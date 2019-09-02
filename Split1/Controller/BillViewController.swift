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
    
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
    
    let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let lightgreyColour = UIColor(red: 236/255, green: 240/255, blue: 241/255, alpha: 1)
    let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
    let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Your Bill"
        
        tableView.register(UINib(nibName: "QuantityTableCell", bundle: nil) , forCellReuseIdentifier: "quantityTableCell")
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(backTapped))
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
    
        loadTables()
        
        fillSectionArray()
        
        setAppearance()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return numberOfSections
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sections[section].foodType
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = lightgreyColour
        
        let headerLabel = UILabel(frame: CGRect(x: 30, y: 0, width:
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
        cell.quantityLabel.text =  ("\(sections[indexPath.section].quantityArray[indexPath.row])")
        cell.spendLabel.text = ("\(sections[indexPath.section].spendArray[indexPath.row])")
        
        cell.isUserInteractionEnabled = false

        return cell
    }


  
    
    func loadTables() {
        
        costEntry = realm.objects(CostEntry.self)
        costEntry = costEntry?.filter("itemSpend > %@", 0.0 as Float)
        costEntry = costEntry!.sorted(byKeyPath: "personName")
        
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        
        settings = realm.objects(Settings.self)
        currencyPrefix = settings?[0].currencyPrefix ?? ""
        screenHeight = settings?[0].screenHeight ?? 0
        
        item = realm.objects(Item.self)

        person = realm.objects(Person.self)

        
//        tableView.reloadData()
    }
    
    func fillSectionArray() {
        
        item = item!.filter("itemSpendNet > %@", 0.0 as Float)
        item = item!.sorted(byKeyPath: "itemName")
        numberOfSections = item!.count
        
        var nameArray: Array<String> = []
        var quantityArray: Array<Int> = []
        var priceArray: Array<Float> = []
        
        if numberOfSections > 0 {
            for m in 0...numberOfSections-1 {
                let sectionHeader = item![m].itemName
                var tableEntry = costEntry!.filter("itemName == %@", sectionHeader)
                tableEntry = tableEntry.filter("itemNumber > %@", 0 as Int)
                
                nameArray = []
                quantityArray = []
                priceArray = []
                
                for n in 0...tableEntry.count-1 {
                    nameArray.append(tableEntry[n].personName)
                    quantityArray.append(tableEntry[n].itemNumber)
                    priceArray.append(tableEntry[n].itemSpend)
                }
                
                let newSecion = TableSection(food: sectionHeader, person: nameArray, quantity: quantityArray, spend: priceArray)
                
                sections.append(newSecion)
                
            } // end for
        } // end if
        
        
    } // end func
    
    func setAppearance(){
        
        var tableRowHeight: CGFloat
        
        switch screenHeight {
        case 1136:
            fontSize = 16; tableRowHeight = 30
        case 1334:
            fontSize = 18; tableRowHeight = 35
        default:
            fontSize = 20; tableRowHeight = 40
        }
        
//        splitterText.font = splitterText.font?.withSize(fontSize)
//        foodText.font = foodText.font?.withSize(fontSize)
//        
        tableView.separatorColor = UIColor.clear
        tableView.rowHeight = tableRowHeight

//        
//        splitterText.layer.cornerRadius = 10.0
//        splitterText.layer.borderColor = orangeColour.cgColor
//        splitterText.layer.borderWidth = 1.0
//        
//        foodText.layer.cornerRadius = 10.0
//        foodText.layer.borderColor = orangeColour.cgColor
//        foodText.layer.borderWidth = 1.0
        
    }

}
