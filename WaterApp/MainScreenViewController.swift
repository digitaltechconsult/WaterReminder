//
//  MainScreenViewController.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 03/03/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import UIKit
import SpriteKit
import iAd
import FloatingActionSheetController
import InAppFw //TODO: Translate
import GoogleMobileAds
import Armchair

/**
 Main Application screen
 */
class MainScreenViewController: WaterViewController, GADBannerViewDelegate {
    
    //MARK: - Water Animation Properties
    
    /// Water image used in the animation
    let waterImage: UIImageView = UIImageView(image: UIImage(imageLiteral: "Water"))
    
    /// Used to save if the animation moved the water up or not
    var animationY: Bool = false
    
    /// Timer that animate the water
    var animationTimer: NSTimer?
    
    //MARK: Bubble Animation Properties
    
    /// SceneKit view used to draw bubble animation
    var skView: SKView?
    
    /// SceneKit scene containing the bubble animation
    var scene: WABubbles?
    
    //MARK: - Other Properties
    
    /// Timer that display the remaining time of the next notification
    var statusTimer: NSTimer?
    
    ///FX Timer
    var fxTimer: NSTimer?
    
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var drinkSizeButton: UIButton!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var purchasesButton: UIButton!
    @IBOutlet weak var bannerView: GADBannerView!
    
    //MARK: - UI Actions
    @IBAction func drinkButtonTap(sender: AnyObject) {
        self.waterLogic.drink {
            self.updateApp()
            dispatch_async(dispatch_get_main_queue()) {
                self.timerAnimate()
                if !self.appDelegate.isAppFullVersion() && self.appIsDisplayingInterstitialAd() {
                    self.displayAdViewController()
                }
            }
        }
        self.trackEvent("Drink")
        Armchair.userDidSignificantEvent(true)
    }
    
    @IBAction func undoButtonTap(sender: AnyObject) {
        self.waterLogic.undoDrink {
            self.updateApp()
            dispatch_async(dispatch_get_main_queue()) {
                self.timerAnimate()
            }
        }
        self.trackEvent("UndoDrink")
    }
    
    @IBAction func changeSizeButtonTap(sender: AnyObject) {
        //general settings
        let backgroundColor = UIColor(colorLiteralRed: 9/255, green: 22/255, blue: 41/255, alpha: 1)
        let font = UIFont(name: "Apple SD Gothic Neo", size: 16)
        
        //change action
        var changeActions: [FloatingAction] = []
        var index: Int = 0
        for value in waterLogic.drinkList {
            //create label
            let value = NSString(format: "%.2f", self.waterLogic.metric ? value : value.metricToImperialVolume) as String
            let unit = self.waterLogic.metric ? "l" : "oz"
            let caption = NSString(format: "%@ %@", value, unit) as String
            let action = FloatingAction(title: caption, handleImmediately: true, tag: index) { action in
                self.changeDrinkSizeAction(action)
            }
            index += 1
            changeActions.append(action)
        }
        //create change action group
        let actionGroupChange = FloatingActionGroup(actions: changeActions.reverse())
        
        //create action sheet
        let actionSheet = FloatingActionSheetController(actionGroups: [actionGroupChange], animationStyle: .Pop)
        // Color of action sheet
        actionSheet.itemTintColor = UIColor(colorLiteralRed: 230/255, green: 234/255, blue: 238/255, alpha: 1.0)
        // Color of title texts
        actionSheet.textColor = backgroundColor
        // Font of title texts
        actionSheet.font =  font!
        // background dimming color
        actionSheet.dimmingColor = backgroundColor.colorWithAlphaComponent(0.72)
        actionSheet.present(self)
        
        self.trackEvent("ChangeSize")
    }
    
    @IBAction func purchasesTap(sender: UIButton) {
        
        let donate = UIAlertAction(title: LocaleStrings.Donate, style: .Default) { alertAction in
            dispatch_async(dispatch_get_main_queue()) {
                self.donateAndRemoveAds()
            }
        }
        
        let restore = UIAlertAction(title: LocaleStrings.RestorePurchases, style: .Default) { alertAction in
            InAppFw.sharedInstance.restoreCompletedTransactions()
        }
        
        let cancel = UIAlertAction(title: LocaleStrings.Cancel , style: .Cancel, handler: nil)
        self.displayAlertView(LocaleStrings.RemoveAds, title: LocaleStrings.Donate, actions: [donate, restore, cancel])
        
        self.trackEvent("PurchasesTap")
    }
    
    func donateAndRemoveAds() {
        InAppFw.sharedInstance.requestProducts { success, products in
            if success {
                //only one product for now
                if let products = products {
                    if products.count > 0 {
                        for product in products {
                            if product.productIdentifier == AppDelegate.InAppPurchases.DonateAndRemoveAds {
                                InAppFw.sharedInstance.purchaseProduct(product)
                                return
                            }
                        }
                    }
                }
            } else {
                self.displayAlertView(LocaleStrings.AppStoreError)
            }
        }
        
    }
    
    @IBAction func openFacebookPage(sender: UIButton) {
        if let facebookURL = NSURL(string: "https://www.facebook.com/WaterReminder") {
            UIApplication.sharedApplication().openURL(facebookURL)
            self.trackEvent("FacebookPage")
        }
    }
    
    func appIsDisplayingInterstitialAd() -> Bool {
        let currentTimestamp = NSDate().timeIntervalSince1970
        if let lastTimestamp = waterLogic.lastInterstitalAdTimestamp {
            if abs(currentTimestamp - lastTimestamp) >= 10800  && ALInterstitialAd.isReadyForDisplay() {
                waterLogic.lastInterstitalAdTimestamp = currentTimestamp
                return true
            }
        } else {
            waterLogic.lastInterstitalAdTimestamp = currentTimestamp
        }
        
        return false
    }
    
    
    
    func changeDrinkSizeAction(action: FloatingAction) {
        if waterLogic.changeDrinkSize(action.tag) {
            let unit = self.waterLogic.metric ? "l" : "oz"
            let value = self.waterLogic.metric ? self.waterLogic.drinkSize : self.waterLogic.drinkSize.metricToImperialVolume
            let labelText = NSString(format: "%.2f%@", value, unit) as String
            dispatch_async(dispatch_get_main_queue()) {
                self.appDelegate.buttonPlayer?.play()
                self.drinkSizeButton.setTitle(labelText, forState: .Normal)
                self.updateApp()
            }
        }
    }
    
    func timerAnimate() {
        guard let timer = self.fxTimer else {
            self.fxTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(fx), userInfo: nil, repeats: false)
            return
        }
        timer.invalidate()
        self.fxTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(fx), userInfo: nil, repeats: false)
    }
    
    
    //MARK: - ViewController Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create water image
        let height: CGFloat = self.view.bounds.height
        let width: CGFloat = self.view.bounds.width * 1.5
        let x: CGFloat = -(width - self.view.bounds.width)/2
        let y: CGFloat = self.view.bounds.height * 0.7
        let rect = CGRectMake(x, y, width, height)
        self.waterImage.frame = rect
        self.view.addSubview(self.waterImage)
        self.addParallaxToView(self.waterImage)
        
        //text & progress bar
        self.rate(0)
        
        //timers
        animationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MainScreenViewController.moveWater), userInfo: nil, repeats: true)
        statusTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MainScreenViewController.updateNotificationText), userInfo: nil, repeats: true)
        
        //bubbles
        self.skView = SKView(frame: self.view.frame)
        if let skView = self.skView {
            self.view.addSubview(skView)
            scene = WABubbles(size: skView.bounds.size)
            scene!.scaleMode = .ResizeFill
            scene!.backgroundColor = UIColor.clearColor()
            skView.allowsTransparency = true
            skView.presentScene(scene!)
        }
        
        //display notification settings
        let tapNotification = UITapGestureRecognizer(target: self, action: #selector(MainScreenViewController.notificationLabelTap(_:)))
        self.notificationLabel.addGestureRecognizer(tapNotification)
        
        //Google Ads
        
        if !appDelegate.isAppFullVersion() {
            print("Google Mobile Ads SDK version: " + GADRequest.sdkVersion())
            
            //test device
            let request = GADRequest()
            request.testDevices = [kGADSimulatorID]
            
            //banner setup
            self.bannerView.hidden = true
            self.bannerView.delegate = self
            self.bannerView.adUnitID = "ca-app-pub-0061072064010371/3164742604"
            self.bannerView.rootViewController = self
            self.bannerView.loadRequest(GADRequest())
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.trackScreenName("MainScreen")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //if it's the first time, go directly to user settings
        if waterLogic.firstRun {
            self.performSegueWithIdentifier("SettingsSegue", sender: nil)
        }
        
        //waterapp logic
        self.updateProgressBar(drinked: self.waterLogic.drinkedWater, total: self.waterLogic.totalWaterQty)
        
        let unit = self.waterLogic.metric ? "l" : "oz"
        let value = self.waterLogic.metric ? self.waterLogic.drinkSize : self.waterLogic.drinkSize.metricToImperialVolume
        let labelText = NSString(format: "%.2f%@", value, unit) as String
        self.drinkSizeButton.setTitle(labelText, forState: .Normal)
        
        //in-app purchases
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseNotification(_:)), name: InAppFw.IAPPNotifications.kIAPPurchasedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(purchaseFailedNotification(_:)), name: InAppFw.IAPPNotifications.kIAPFailedNotification, object: nil)
        self.manageAds()
        
        self.waterLogic.resetDrinks()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: InAppFw.IAPPNotifications.kIAPPurchasedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: InAppFw.IAPPNotifications.kIAPFailedNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    func notificationLabelTap(sender: UILabel) {
        if let notificationSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(notificationSettings)
        }
    }
    
    override func updateApp() {
        super.updateApp()
        self.statusTimer?.invalidate()
        appDelegate.scheduleNotifications {
            dispatch_async(dispatch_get_main_queue()) {
                self.statusTimer =  NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MainScreenViewController.updateNotificationText), userInfo: nil, repeats: true)
            }
        }
    }
    
    //MARK: - IN-APP purchase
    func manageAds() {
        if appDelegate.isAppFullVersion() {
            dispatch_async(dispatch_get_main_queue()) {
                self.bannerView.hidden = true
                self.purchasesButton.hidden = true
                self.bannerView.delegate = nil
            }
            print(">>>>>>> No ads! <<<<<<<<<")
        }
    }
    
    func displayAdViewController() {
        let storyboard = UIStoryboard(name: "UI_v2", bundle: nil)
        let viewController = storyboard.instantiateViewControllerWithIdentifier("FullScreenAd") as! FullScreenAdViewController
        self.presentViewController(viewController, animated: true, completion: nil)
    }
    
    func purchaseNotification(notification: NSNotification) {
        if let productId = notification.object as? String {
            
            if productId == AppDelegate.InAppPurchases.DonateAndRemoveAds {
                self.displayAlertView(LocaleStrings.Donate, title: LocaleStrings.AdsDisabled)
                self.manageAds()
            }
            
        }
    }
    
    func purchaseFailedNotification(notification: NSNotification) {
        self.displayAlertView(LocaleStrings.AppStoreError)
    }
    
    
    
    //MARK: - Animations & Effects
    
    /// Special Effects - Plays the sounds and shows bubbles animations
    func fx() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            self.appDelegate.drinkPlayer?.play()
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.scene?.addBubbles(CGPointMake(self.view.bounds.width * 0.5, 0))
        }
    }
    
    /// Called by timer, to simulate the water movement
    func moveWater() {
        UIView.animateWithDuration(1) {
            let defaultX = -(self.view.bounds.width * 1.5 - self.view.bounds.width)/2
            let newX = self.waterImage.frame.origin.x > defaultX ? defaultX - 6 : defaultX + 6
            
            let newY = self.animationY ? self.waterImage.frame.origin.y - 4 : self.waterImage.frame.origin.y + 4
            self.animationY = !self.animationY
            
            let rect = CGRectMake(newX, newY, self.waterImage.frame.width, self.waterImage.frame.height)
            self.waterImage.frame = rect
        }
    }
    
    /**
     Adds parallax effect to a `UIView`
     - parameters:
     - vw: the view that will have parallax effect
     */
    func addParallaxToView(vw: UIView) {
        let xAmount = (self.waterImage.frame.width - self.view.bounds.width)/2
        let yAmount = 35
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .TiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -xAmount
        horizontal.maximumRelativeValue = xAmount
        
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .TiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -yAmount
        vertical.maximumRelativeValue = yAmount
        
        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
    }
    
    /**
     Change the displayed water level
     - parameters:
     - percentage: a value between 0 and 100
     */
    func rate(percentage: Double) {
        let min: CGFloat = self.view.bounds.height * 0.7
        let max: CGFloat = self.view.bounds.height * 0.1
        let step: CGFloat = (max - min) / 100
        
        let yPosition = min + CGFloat(percentage) * step < max ? max : min + CGFloat(percentage) * step
        
        let rect = CGRectMake(self.waterImage.frame.origin.x, yPosition, self.waterImage.frame.width, self.waterImage.frame.height)
        UIView.animateWithDuration(1.25) {
            self.waterImage.frame = rect
        }
    }
    
    //MARK: - MainScreen Methods
    
    /// Called by timer to display the text related to next notification
    func updateNotificationText() {
        var text: String = ""
        if let notificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if notificationSettings.types != UIUserNotificationType.None {
                
                if let nextNotification = self.waterLogic.nextNotification() {
                    let notificationTime = nextNotification.fireDate!.timeIntervalSince1970
                    let secondsToFire = notificationTime - NSDate().timeIntervalSince1970
                    
                    text = LocaleStrings.NextAlarm
                    
                    //compute hours, min and seconds
                    let hours = Int(secondsToFire / 3600)
                    if hours > 0 {
                        text = "\(text)\(hours)h"
                    }
                    let minutes = Int(secondsToFire - Double(hours * 3600)) / 60
                    if minutes > 0 {
                        text = hours > 0 ? "\(text) \(LocaleStrings.And) " : "\(text)"
                        text = "\(text)\(minutes)min"
                    }
                    if hours <= 0 && minutes <= 0 {
                        text = "\(text)\(LocaleStrings.LessThanAMin)"
                    }
                } else {
                    text = LocaleStrings.HydrateYourBody
                }
            } else {
                text = LocaleStrings.TapToEnableNotifications
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.notificationLabel.text = text
        }
        
    }
    
    /// Updates the interface when the drinked water has changed
    func updateProgressBar(drinked drinked: Double, total: Double) {
        if !self.waterLogic.firstRun {
            dispatch_async(dispatch_get_main_queue()) {
                //update water progress
                let percent = drinked/total * 100
                self.rate(percent)
                
                //update labels
                let unit = self.waterLogic.metric ? "l" : "oz"
                self.percentageLabel.text = NSString(format: "%.0f%%", percent) as String
                let drinkedValue = self.waterLogic.metric ? drinked : drinked.metricToImperialVolume
                let totalValue = self.waterLogic.metric ? total : total.metricToImperialVolume
                self.quantityLabel.text = NSString(format: "%.2f\(unit) of %.2f\(unit)", drinkedValue, totalValue) as String
            }
        }
    }
    
    //MARK: - WaterLogic Protocol
    
    /// See `WaterViewController` delegate for more information
    override func updateRequired() {
        super.updateRequired()
        self.updateProgressBar(drinked: self.waterLogic.drinkedWater, total: self.waterLogic.totalWaterQty)
    }
    

    //MARK: - Google Ads Delegate
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        bannerView.hidden = false
    }
    
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        bannerView.hidden = true
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    
}
