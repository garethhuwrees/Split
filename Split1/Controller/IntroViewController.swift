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
    
    let greyColour: UIColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    let splitFont: String = "Lemon-Regular"
    let regularFont: String = "Roboto-Regular"
    let mediumFont: String = "Roboto-Medium"
    let boldFont = "Roboto-Bold"
    
    let guideString = NSMutableAttributedString()

    var fontSize: CGFloat = 20
    
    //MARK:----------- VIEW DID LOAD -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = realm.objects(Settings.self)
        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(backTapped))
        
        titleTest.isUserInteractionEnabled = false
        subtitleText.isUserInteractionEnabled = false
        subTitle2Text.isUserInteractionEnabled = false
        
        if introType == "story" {
            self.title = "Background"
        }
        
        else {
            self.title = "User Guide"
        }
        
        setAppearance()
        setupGuideText()
        setMessage()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
    }
    
    //MARK:------------------- SEGUE -------------------------
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == .left {
            backTapped()
        }
        
        if gesture.direction == .up {
            backTapped()
        }
    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        if introType == "guideSwipe" {
            trans.type = CATransitionType.reveal
            trans.subtype = CATransitionSubtype.fromTop
        }
        else {
            trans.type = CATransitionType.push
            trans.subtype = CATransitionSubtype.fromRight
        }
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }
    
    //MARK:------------ LOCAL FUNCTIONS --------------------------
    
    
    func setAppearance() {
        
        
        let  screenHeight = settings?[0].screenHeight ?? 1334
        
        switch screenHeight {
        case 1136:
            fontSize = fontSize - 7 //13
        case 1334:
            fontSize = fontSize - 5 //15
        default:
            fontSize = fontSize - 3 //17
        }
        
        titleTest.font = UIFont(name: splitFont, size: fontSize+18)
        subtitleText.font = UIFont(name: boldFont, size: fontSize+4)
        subTitle2Text.font = UIFont(name: mediumFont, size: fontSize+2)
        storyText.font = UIFont(name: regularFont, size: fontSize)
        
        let leftbutton = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.backTapped))
        leftbutton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: regularFont, size: fontSize + 2)!], for: UIControl.State.normal)
        navigationItem.leftBarButtonItem = leftbutton

        titleTest.text = "SPLTOPIA"
        subtitleText.text = "Helping Maintain World Peace"
        subTitle2Text.text = "one meal at a time"
    }
    

    func setMessage() {
        
        if introType == "story" {
            storyText.text = story1
        }
        else {
            storyText.attributedText = guideString
        }
    }
    
    func setupGuideText() {
        
        let normalAttribute = [NSMutableAttributedString.Key.font : UIFont(name: regularFont, size: fontSize), NSMutableAttributedString.Key.foregroundColor: greyColour]
        let boldAttribute = [NSMutableAttributedString.Key.font : UIFont(name: mediumFont, size: fontSize), NSMutableAttributedString.Key.foregroundColor: greyColour]
        
        let guide1 = "To start using SPLITOPIA, swipe left from the "
        let guide2 = " page and then touch the icons at the bottom of "
        let guide3 = " to add the names of the 'Leaders' (the people around the table) and the type of ‘Food & Drink’ they will order (e.g. appetizer, main, dessert, sides, beer, wine etc.).\nYou can then select any row in the table to record spend by either Leader or Food & Drink item. Swipe left on a Food & Drink item to set a unit price and then just change the quantity.\n\nBack on the "
        let guide4 = " page you can set the local tax rate and percentage tip. There is also an option to enter a 'Fixed Amount' if you wish to round the bill or deduct a money off coupon - this will be highlighted if less than the total spend.\nTouch the header in the bottom box of the "
        let guide5 = " page to cycle through the Leader's spend based on the options in the top box.\nA couple of things to note:\n- The 'Fixed Amount' is based on the Leader's proportion of the total spend\n- The tip is calculated from spend before tax, some establishments may add this after tax.\n\n The icons at the bottom of the "
        let guide6 = " page allows you to round to the major currency unit, reset the underlying data (ready for the next meal) and set a currency symbol\n\nFinally, from the "
        let guide7 = " page you can swipe right to "
        let guide8 = " and see a breakdown of everything ordered."
        
        
        let summary = NSMutableAttributedString(string: "Summary", attributes: boldAttribute as [NSAttributedString.Key : Any])
        let yourTable = NSMutableAttributedString(string: "Your Table", attributes: boldAttribute as [NSAttributedString.Key : Any])
        let yourBill = NSMutableAttributedString(string: "Your Bill", attributes: boldAttribute as [NSAttributedString.Key : Any])
        
        let guide1Attr = NSAttributedString(string: guide1, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide2Attr = NSAttributedString(string: guide2, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide3Attr = NSAttributedString(string: guide3, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide4Attr = NSAttributedString(string: guide4, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide5Attr = NSAttributedString(string: guide5, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide6Attr = NSAttributedString(string: guide6, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide7Attr = NSAttributedString(string: guide7, attributes: normalAttribute as [NSAttributedString.Key : Any])
        let guide8Attr = NSAttributedString(string: guide8, attributes: normalAttribute as [NSAttributedString.Key : Any])
        
        guideString.append(guide1Attr)
        guideString.append(summary)
        guideString.append(guide2Attr)
        guideString.append(yourTable)
        guideString.append(guide3Attr)
        guideString.append(summary)
        guideString.append(guide4Attr)
        guideString.append(summary)
        guideString.append(guide5Attr)
        guideString.append(summary)
        guideString.append(guide6Attr)
        guideString.append(summary)
        guideString.append(guide7Attr)
        guideString.append(yourBill)
        guideString.append(guide8Attr)
    }
    
    
    let story1 = "Picture the scene: it's the G7 summit in France and after a tense and exhausting day negotiating carbon emissions and global trade, our world leaders are sitting down to relax at a well deserved dinner. However, there is a problem when the bill arrives: Donald had his usual steak and ketchup with soda, Shinzo ordered the tuna appetizer, Emmanuel polished off an entire bottle of very fine Bordeaux by himself, Justin had the eye-wateringly expensive fish special and Boris went heavy on the sweet trolley. No way is Donald dividing the bill equally seven ways.\n\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPITOPIA each of the leaders paid exactly their fair share of the bill and harmony was once again restored (or at least some level of cordiality). And at the same time they were able to satisfy themselves that the bill did not include anything ordered by members of the Chinese Politburo dining on the next table.\n\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and global trade."
    
    let story2 = "Picture the scene: it's the G7 summit in France and after a day negotiating carbon emissions and global trade, our world leaders are sitting down to a well deserved dinner. However, there is a problem when the bill arrives: Donald had his usual steak with ketchup, Shinzo went for a tuna appetizer, Emmanuel had an entire fine Bordeaux to himself, and Boris went heavy on the sweet trolley. No way is he Donald dividing the bill equally 7 ways.\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPLITOPIA each of the leaders paid exactly their fair share of the bill and harmony was once again restored.\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and global trade."
    
    let story3 = "Our world leaders can’t agree on world trade or carbon emissions, so why after a hard day of negotiations would they agree to divide the cost of dinner equally.\nWell they could use SPLITOPIA to record who consumed what and each then pays their own share of the bill. Harmony is maintained. The only thing left to agree upon is how much tip to leave! Oh, and carbon emissions and global trade."
    
    
    
    let instruction = "To start using SPLITOPIA, swipe left from the Summary page and then touch the icons at the bottom of 'Your Table' to add the names of the leaders at the table and the type of Food & Drink they will order (e.g. appetizer, main, dessert, sides, beer, wine etc.).\nYou can then select any row in the table to record spend by either Leader or Food & Drink item. Or swipe left on a Food & Drink item to set a unit price and then just change the quantity.\n\nOn the Home page you can set the local tax rate and percentage tip. There is also an option to enter a 'Fixed Amount' if you wish to round the bill or deduct a money off coupon - this will be highlighetd if less than the total spend.\nTouch the header in the bottom box of the Home page to cycle through the Leader's spend based on the options in the top box.\nA couple of things to note:\n- The 'fixed amount' is based on the Leader's proportion of the total spend\n- The tip is calculated from spend before tax, some establishments may add this after tax.\n\n The icons at the bottom of the Home page allows you to round to the major currency unit, reset the underlying data (ready for the next meal) and set a currency symbol\n\nFinally, from the Home page you can swipe right to see a summary of everything ordered."
    
}


