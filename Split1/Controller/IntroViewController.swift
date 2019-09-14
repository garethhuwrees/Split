//
//  IntroViewController.swift
//  Split1
//
//  Created by Gareth Rees on 24/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift


protocol RecieveIntro { //Found that this must be unique (different from protocol in
    
    func dataRecieved(data : String) // The method has no body, it just sets out the 'rules of engagement'
}

class IntroViewController: UIViewController {
    
    var deligate : RecieveIntro?
    var introType : String?
    
    var settings: Results<Settings>?
    let realm = try!Realm()
    
    
    @IBOutlet weak var titleTest: UITextField!
    @IBOutlet weak var subtitleText: UITextField!
    @IBOutlet weak var subTitle2Text: UITextField!
    @IBOutlet weak var storyText: UITextView!
    
    let textColour: UIColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let splitFont: String = "Lemon-Regular"
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
    
    //MARK:----------- VIEW DID LOAD -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = realm.objects(Settings.self)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(backTapped))
        
        titleTest.isUserInteractionEnabled = false
        subtitleText.isUserInteractionEnabled = false
        subTitle2Text.isUserInteractionEnabled = false
        
        if introType == "story" {
            self.title = "The Story"
        }
        
        else {
            self.title = "User Guide"
        }
        
        setAppearance()
        setMessage()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    //MARK:------------------- SEGUE -------------------------
    
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
    
    //MARK:------------ LOCAL FUNCTIONS --------------------------
    
    
    func setAppearance() {
        
        let  screenHeight = settings?[0].screenHeight ?? 1334
        
        var textHeight: CGFloat = 0.0
        
        switch screenHeight {
        case 1136:
            textHeight = 13
        case 1334:
            textHeight = 15
        default:
            textHeight = 17
            
        }
        
        titleTest.font = UIFont(name: splitFont, size: textHeight+18)
        subtitleText.font = UIFont(name: boldFont, size: textHeight+4)
        subTitle2Text.font = UIFont(name: mediumFont, size: textHeight+2)
        storyText.font = UIFont(name: regularFont, size: textHeight)

        titleTest.text = "SPLIT!"
        subtitleText.text = "Helping Maintain World Peace"
        subTitle2Text.text = "one meal at a time"
    }

    func setMessage() {
        
        if introType == "story" {
            storyText.text = story1
        }
        if introType == "guide" {
            storyText.text = instruction
        }
        
    }
    
    
    let story1 = "Picture the scene: it is the G7 summit and after a tense and exhausting day negotiating carbon emissions and global trade, our world leaders are sitting down to relax at a well deserved dinner. However, there is a problem when the bill arrives: Donald had his usual steak and ketchup with soda, Shinzo ordered the tuna appetizer, Emmanuel polished off an entire bottle of very fine Bordeaux by himself, Justin had the eye-wateringly expensive fish special and Boris went heavy on the sweet trolley. No way is Donald dividing the bill equally seven ways.\n\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPLIT! each of the leaders paid their fair share of the bill and harmony was once again restored (or at least some level of cordiality). And at the same time they were able to satisfy themselves that the bill did not include anything ordered by members of the Chinese Politburo dining on the next table.\n\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and global trade."
    
    let story2 = "Picture the scene: it is the G7 summit and after a day negotiating carbon emissions and global trade, our world leaders are sitting down to a well deserved dinner. However, there is a problem when the bill arrives: Donald had his usual steak with ketchup, Shinzo went for a tuna appetizer, Emmanuel had an entire fine Bordeaux to himself, and Boris went heavy on the sweet trolley. No way is he Donald dividing the bill equally 7 ways.\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPLIT! each of the leaders paid their fair share of the bill and harmony was once again restored.\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and global trade."
    
    let story3 = "Our world leaders can’t agree on world trade or carbon emissions, so why after a hard day of negotiations would they agree to divide the cost of dinner equally.\nWell they could use SPLIT! to record who consumed what and each then pays their own share of the bill. Harmony is maintained. The only thing left to agree upon is how much tip to leave! Oh, and carbon emissions and global trade."
    
    let instruction = "To start using SPLIT!, swipe left from the Home page and then touch the icons at the bottom of 'Your Table' to add the names of the people at the table (the 'Splitters') and the type of ‘Menu Items’ they will order (e.g. appetize, main, dessert, sides, beer, wine etc.).\nYou can then select any row in the table to record spend by either Splitter or Menu Item. Or swipe left on a Menu Item to set a unit price and then just change the quantity.\n\nOn the Home page you can set the local tax rate and percentage tip. There is also an option to enter a 'Fixed Amount' if you wish to round the bill or deduct a money off coupon - this will be highlighetd if less than the total spend.\nTouch the header in the bottom box of the Home page to cycle through the Splitter's spend based on the options in the top box.\nA couple of things to note:\n- The 'fixed amount' is based on the Splitter's proportion of the total spend\n- The tip is calculated from spend before tax, some establishments may add this after tax.\n\n The icons at the bottom of the Home page allows you to round to the major currency unit, reset the underlying data (ready for the next meal) and set a currency symbol/n/nFinally, from the Home page you can swipe right to see a summary of everything ordered."
    
}
