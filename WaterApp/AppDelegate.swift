//
//  AppDelegate.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 1/26/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import UIKit
import AVFoundation
import InAppFw
import Armchair

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WaterLogicProtocol {
    
    var window: UIWindow?
    var ur: Int = 0
    
    /**
     In-App Purchases Products
     */
    struct InAppPurchases {
        static let oldNoAds = "NoAdds"
        static let DonateAndRemoveAds = "ro.selrys.waterapp.310886_donate"
    }
    
    /// `WaterLogic singleton` shared object
    var waterLogic: WaterLogic {
        get {
            return WaterLogic.sharedInstance
        }
    }
    
    /// global background notification queue, used to schedule the notifications
    let notificationQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
    
    /// the `NSURL` of the button sound
    let buttonSound = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("button", ofType: "wav")!)
    
    /// the `NSURL` of the drink action sound
    let drinkSound = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("drink", ofType: "wav")!)
    
    /// button sound player
    var buttonPlayer: AVAudioPlayer?
    
    /// drink sound player
    var drinkPlayer: AVAudioPlayer?
    
    //MARK: AppDelegate Default Methods
    
    
    /// Initialize the `WaterLogic` shared object, schedule the notifications and initialise the sounds
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        waterLogic.delegate = self
        
        //schedule notifications
        self.registerForLocalNotifications(application)
        
        //clear notifications badges and re-count their badge number
        if let notifications = self.resetNotificationBadgeCount(UIApplication.sharedApplication().scheduledLocalNotifications) {
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            for notification in notifications {
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
            }
        }
        
        //sounds
        self.initSounds()
        
        //AppLovin SDK
        if !self.isAppFullVersion() {
            ALSdk.initializeSdk()
        }
        
        //in-app purchases
        InAppFw.sharedInstance.addProductId(AppDelegate.InAppPurchases.DonateAndRemoveAds)
        InAppFw.sharedInstance.loadPurchasedProducts(false, completion: nil)
        
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.Verbose  // remove before app release
        
        //Armchair - for rating
        Armchair.appID("1083872588")
        Armchair.significantEventsUntilPrompt(5)
        Armchair.daysUntilPrompt(3)
        
        return true
    }
    
    /// Handles the in-notification actions
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        if notification.category == "DRINK_CATEGORY" {
            
            switch identifier! {
            case "DRINK_ACTION":
                self.waterLogic.drink {
                    self.waterLogic.saveState()
                    self.scheduleNotifications {
                        completionHandler()
                    }
                }
            case "LATER_ACTION":
                waterLogic.postponeNotification(notification)
                completionHandler()
            default:
                completionHandler()
                print("Nothing to do")
            }
        }
    }
    
    /// Notifies the currently displayed `WaterViewController` that a notification has fired
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        NSNotificationCenter.defaultCenter().postNotificationName("WaterForegroundNotification", object:nil, userInfo:["localNotification":notification])
        
        print("\(NSDate()): Foreground notification called!")
    }
    
    /// Saves the state of the application
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        waterLogic.saveState()
    }
    
    /// Loads the state of the application
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        waterLogic.loadState(false)
        waterLogic.loadUserSettings(false)
        waterLogic.resetDrinks()
        if let notifications = self.resetNotificationBadgeCount(UIApplication.sharedApplication().scheduledLocalNotifications) {
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            for notification in notifications {
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
            }
        }
    }
    
    /// Saves the state of the application
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        waterLogic.saveState()
    }
    
    //MARK: - App Methods
    
    /**
     Schedule the notifications by using the `WaterLogic` notification logic.
     - parameters:
     - completion: callback called before exit
     */
    func scheduleNotifications(completion:(()->Void)?) {
        dispatch_async(self.notificationQueue) {
            guard let notificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings() else {
                return
            }
            
            if !self.waterLogic.firstRun && notificationSettings.types.contains(.Alert) {
                UIApplication.sharedApplication().cancelAllLocalNotifications()
                
                if let notifications = self.waterLogic.scheduleNotifications(2) { //do it for 3 days in advance
                    if let finalNotifications = self.resetNotificationBadgeCount(notifications) {
                        for notification in finalNotifications {
                            UIApplication.sharedApplication().scheduleLocalNotification(notification)
                        }
                    }
                }
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    /**
     Creates the category used in interactive notifications and register for notifications
     - parameters:
     - application: the current application shared instance
     */
    func registerForLocalNotifications(application: UIApplication) {
        //create dynamic notifications
        //create the action
        let drinkAction = UIMutableUserNotificationAction()
        drinkAction.identifier = "DRINK_ACTION"
        drinkAction.title = LocaleStrings.Drink
        drinkAction.activationMode = UIUserNotificationActivationMode.Background
        drinkAction.authenticationRequired = true
        drinkAction.destructive = false
        
        let laterAction = UIMutableUserNotificationAction()
        laterAction.identifier = "LATER_ACTION"
        laterAction.title = LocaleStrings.Later
        laterAction.activationMode = UIUserNotificationActivationMode.Background
        laterAction.authenticationRequired = false
        laterAction.destructive = false
        
        //create categories
        let drinkCategory = UIMutableUserNotificationCategory()
        drinkCategory.identifier = "DRINK_CATEGORY"
        drinkCategory.setActions([drinkAction,laterAction], forContext: UIUserNotificationActionContext.Default)
        drinkCategory.setActions([drinkAction,laterAction], forContext: UIUserNotificationActionContext.Minimal)
        
        //register for notifications
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: NSSet(object: drinkCategory) as? Set<UIUserNotificationCategory>))
        print("registered for notification called")
    }
    
    /// Initialize the sounds and gets a shared audioSession
    func initSounds() {
        do {
            //don't stop background music
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryAmbient, withOptions: .MixWithOthers)
            
            //create sounds
            self.buttonPlayer = try AVAudioPlayer(contentsOfURL: self.buttonSound)
            self.buttonPlayer?.volume = 0.05
            self.drinkPlayer = try AVAudioPlayer(contentsOfURL: self.drinkSound)
            self.drinkPlayer?.volume = 0.10
        } catch {
            print("Error playing sounds")
        }
    }
    
    /**
     Reset the notification badge number for an array of local notifications.
     - parameters:
        - notifications: array of local notifications to be changed
     - returns: array of local notifications with badge count calculated chronological
    */
    func resetNotificationBadgeCount(notifications: [UILocalNotification]? ) -> [UILocalNotification]? {
        if let notificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if notificationSettings.types.contains(.Badge) {
                
                UIApplication.sharedApplication().applicationIconBadgeNumber = -1
                if let notifications = notifications {
                    
                    let sortedNotifications = notifications.sort { (n1, n2) -> Bool in
                        return n1.fireDate?.timeIntervalSince1970 <= n2.fireDate?.timeIntervalSince1970
                    }
                    
                    var index = 1
                    for notification in sortedNotifications {
                        notification.applicationIconBadgeNumber = index
                        index += 1
                    }
                    return sortedNotifications
                }
            }
        }
        return nil
    }
    
    // MARK: - Delegates
    
    /// `WaterLogicProtocol` delegate method that notifies about the changes the currently displayed `ViewController`
    func updateRequired() {
        NSNotificationCenter.defaultCenter().postNotificationName("WaterUpdateRequired", object: nil)
    }
    
    /// `WaterLogicProtocol` delegate method that loads user settings from `HealthKit` as soon as `HealthKit` is available
    func healthKitReady() {
        self.waterLogic.hkWaterLogic?.hkRetrieveUserSettings()
    }
    
    // MARK: - In-App purchases
    func isAppFullVersion() -> Bool{
        let noAds = InAppFw.sharedInstance.productPurchased(InAppPurchases.DonateAndRemoveAds)
        return noAds.isPurchased
    }
}

