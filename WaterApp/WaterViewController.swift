//
//  WaterViewController.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 3/1/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import UIKit


/**
 `UIViewController` subclass used in the application screens. It provides the defaults used by all the screens in the app.
*/
class WaterViewController: UIViewController {
    
    /// returns the shared `WaterLogic` object, declared in the `AppDelegate`
    var waterLogic: WaterLogic {
        get {
            return (UIApplication.sharedApplication().delegate as! AppDelegate).waterLogic
        }
    }
    
    /// returns the `AppDelegate` shared object
    var appDelegate: AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }
    
    /**
     Overrides the default `viewDidAppear` by adding `NSNotificationCenter` observers for updating the UI and display in-app notifications
    */
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WaterViewController.updateRequired), name: "WaterUpdateRequired", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(WaterViewController.foregroundNotification(_:)), name: "WaterForegroundNotification", object: nil)
    }
    
    /**
     Convenience method that is called when `WaterLogic delegate` object calls the `updateRequired` method (`WaterLogicProtocol`).
     In this current implementation, the delegate is `AppDelegate` and the action is passed to the shown `ViewController` via `NSNotificationCenter`
    */
    func updateRequired() {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        guard let _ = self.waterLogic.nextNotification() else {
            appDelegate.scheduleNotifications(nil)
            return
        }
    }
    
    /**
     Displays an alert containing the notification
    */
    func foregroundNotification(notification: NSNotification) {
        let alertText = (notification.userInfo!["localNotification"] as! UILocalNotification).alertBody!
        let drinkAction = UIAlertAction(title: LocaleStrings.Drink, style: .Default) { (action) -> Void in
            self.waterLogic.drink {
                self.updateApp()
            }
        }
        
        let laterAction = UIAlertAction(title: LocaleStrings.Later, style: .Cancel) { (action) -> Void in
            self.waterLogic.postponeNotification(notification.userInfo!["localNotification"] as! UILocalNotification)
        }
        
        self.displayAlertView(alertText, title:"Water Reminder", actions:[drinkAction, laterAction])
    }
    
    /**
     Convenience method to mostly update the app ui. It simulates `updateRequired` call.
    */
    func updateApp() {
        self.updateRequired()
    }
    
    /**
     Remove the `NSNotificationCenter` observers.
    */
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WaterUpdateRequired", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "WaterForegroundNotification", object: nil)
        super.viewWillDisappear(animated)
    }
    
    /**
     By default, hides the status bar
    */
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    /**
     By default uses a Light style status bar
    */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    //MARK: Google
    func trackScreenName(screenName: String) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.allowIDFACollection = true;
        tracker.set(kGAIScreenName, value: screenName)
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject:AnyObject])
    }
    
    func trackEvent(eventName: String) {
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.allowIDFACollection = true;
        let event = (GAIDictionaryBuilder.createEventWithCategory("ui_action", action: "button_press", label: eventName, value: nil).build()) as [NSObject:AnyObject]
        tracker.send(event)
    }

}
