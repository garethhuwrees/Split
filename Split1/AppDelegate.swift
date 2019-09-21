//
//  AppDelegate.swift
//  Split1
//
//  Created by Gareth Rees on 14/06/2019.
//  Copyright © 2019 Gareth Rees. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      
        // Print directory path to the Realm database
//        print(Realm.Configuration.defaultConfiguration.fileURL)
        
        // Initialise the Realm database
        do {
            //let realm = try Realm()
            _ = try Realm()
            } catch {
                print("Error initialising real, \(error)")
            }
        
        // Set Navigation bar appearance
        
        // Cannot get font name and size to work correctly
        
        let screenHeight = Int(UIScreen.main.nativeBounds.height)
        
        print(screenHeight)

        let greyColour = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1)
        let greenColour = UIColor(red: 22/255, green: 160/255, blue: 132/255, alpha: 1)
//        let orangeColour = UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)

//        let regularFont: String = "Chalkduster"
        let regularFont: String = "Roboto-Regular"

        var textHeight: CGFloat = 0.0

        switch screenHeight {
        case 1136:
            textHeight = 10
        case 1334:
            textHeight = 20
        default:
            textHeight = 22
        }

        let navigationBarAppearace = UINavigationBar.appearance()

        navigationBarAppearace.tintColor = UIColor.white
//        navigationBarAppearace.tintColor = greyColour
        navigationBarAppearace.barTintColor = greenColour

        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: regularFont, size: textHeight)!]
        
        navigationBarAppearace.titleTextAttributes = [NSAttributedString.Key.foregroundColor: greyColour]

        
        return true
        
       
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        // CAN'T RECALL WHY THIS CODE IS HERE - WAS IT AN ATTEMPT TO USE USER DEFAULTS?
        
//        let appDeligate = UIApplication.shared.delegate as! SplitViewController
//
//        appDeligate.updateSettings()
    
//        let mainVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SplitViewController") as! SplitViewController
//
////        let mainVC = UIStoryboard(name: "Main", bundle: "nil").instantiateViewController(withIdentifier:"SplitViewController") as! SplitViewController
//        mainVC.updateSettings()
//        print (mainVC.percentageTip)

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func updateSettings() {
        
    }

    
    }




