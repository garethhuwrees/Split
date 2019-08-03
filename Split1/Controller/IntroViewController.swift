//
//  IntroViewController.swift
//  Split1
//
//  Created by Gareth Rees on 24/07/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

class IntroViewController: UIViewController {
    
    var settings: Results<Settings>?
    let realm = try!Realm()
    
    
    @IBOutlet weak var titleTest: UITextField!
    @IBOutlet weak var subtitleText: UITextField!
    @IBOutlet weak var subTitle2Text: UITextField!
    @IBOutlet weak var storyText: UITextView!
    @IBOutlet weak var instructionText: UITextView!
    
  
    
    
    let textColour: UIColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settings = realm.objects(Settings.self)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SPLIT!", style: .plain, target: self, action: #selector(backTapped))
        
        titleTest.isUserInteractionEnabled = false
        subtitleText.isUserInteractionEnabled = false
        subTitle2Text.isUserInteractionEnabled = false
//        storyText.isUserInteractionEnabled = false
//        instructionText.isUserInteractionEnabled = false
        
        self.title = "The Story"
        
        setFontAndMessage()


    }
    
    @objc func backTapped() {
        
        let trans = CATransition()
        trans.type = CATransitionType.push
        trans.subtype = CATransitionSubtype.fromLeft
        trans.duration = 0.35
        self.navigationController?.view.layer.add(trans, forKey: nil)
        navigationController?.popViewController(animated: false)
    }
    
    
    func setFontAndMessage() {
        
        let  iphoneType = settings?[0].phoneType ?? ""
        
        var textHeight: CGFloat = 0.0
        
        switch iphoneType {
        case "5,SE":
            textHeight = 13
            storyText.text = story3
        case "6,7,8":
            textHeight = 14
            storyText.text = story2
        default:
            textHeight = 15
            storyText.text = story1
            
        }
        
        titleTest.font = titleTest.font?.withSize(textHeight+8)
        subtitleText.font = subtitleText.font?.withSize(textHeight+6)
        subTitle2Text.font = subTitle2Text.font?.withSize(textHeight+4)
        storyText.font = storyText.font?.withSize(textHeight)
        instructionText.font = instructionText.font?.withSize(textHeight)
        
        titleTest.text = "SPLIT!"
        subtitleText.text = "Helping To Maintain World Peace"
        subTitle2Text.text = "one meal at a time"
        instructionText.text = instruction
        
    }
    
    
    let story1 = "Picture the scene: it is the G8 summit and after a day negotiating carbon emissions and world trade, our world leaders are sitting down to relax at a well deserved dinner. However, there is a problem when the bill arrives: Donald had a simple burger meal with soda, while Vladimir ordering a caviar starter, Francois drank a whole bottle of a very fine burgundy himself, Justin had the expensive fish ‘special’ and Boris went heavy on the sweet trolley. No way is he dividing the bill equally 8 ways.\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPLIT!each of the leaders paid their fare share of the bill and harmony was once again restored (or at least some level of cordiality). And at the same time they were also able to satisfy themselves that the bill did not include anything ordered by members of the Chinese Politburo dining on the next table.\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and world trade."
    
    let story2 = "The scenario: it is the G8 summit and after a day negotiating carbon emissions and world trade, our world leaders are sitting down to a well deserved dinner. However, there is a problem when the bill arrives: Donald had a simple burger meal with soda, while Vladimir ordering a caviar starter, Francois drank a  bottle of burgundy and Boris went heavy on the sweet trolley. No way is he dividing the bill equally 8 ways.\nStep in Angela, iPhone in hand. “Ach so lieblings. So who ordered what?” Thanks to SPLIT! each of the leaders paid their fare share of the bill and harmony was once again restored.\nNow the only thing to agree on is how much tip to leave! Oh, and carbon emissions and world trade."
    
    let story3 = "Our world leaders can’t agree on world trade or carbon emissions, so why after a hard day of negotiations would they agree to divide the cost of dinner equally.\nWell they could use SPLIT! to record who consumed what and each then pays their own share of the bill. Harmony is maintained. The only thing left to agree upon is how much tip to leave! Oh, and carbon emissions and world trade."
    
    let instruction = "To use SPLIT! just enter the names of the people around the table (Splitters) and the type of ‘menu items’ to be recorded (e.g. starter, main, dessert, sides, drinks).\nYou can record individual spend by Splitter or menu item."
    
}
