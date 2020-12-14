//
//  WaterLogic.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 12/02/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import HealthKit

/**
 Contains the entire logic of the application. The default measurement unit is considered to be metric, so all computations and sizes are done in metric.
 The class is grouped into several files, as following:
 - `WaterLogic.swift` - contains all the class properties. It also contains the methods related to water drinking
 - `WaterLogicPersistentStorageExtension.swift` - methods related to persistent storage operations (save & load)
 - `WaterLogicNotificationsExtension.swift` - methods related to notifications
 - `WaterLogicHealthExtension.swift` - methods used for HealthKit
 */
class WaterLogic {
    
    //MARK: - Class Properties
    
    /// Array containing drink sizes; this is for internal class use. To get the current drink size, use property `drinkSize: Double`
    private let drinkSizeList: [Double] =  [0.2, 0.25, 0.33, 0.5, 0.75, 1.0, 1.5]
    
    /// Selected drink size. It represents the index of `drinkSizeList` array.
    /// Do not set this directly, instead use `changeDrinkSize(drinkType: Int) -> Bool`
    var selectedDrinkSize: Int = 0
    
    /// Read-only propriety, returns the current drink size
    internal var drinkSize: Double {
        get {
            return self.drinkSizeList[selectedDrinkSize]
        }
    }
    
    ///read-only, retrive drink size list
    var drinkList: [Double] {
        get {
            return self.drinkSizeList
        }
    }
    
    /// Store the quantity of drinked water
    internal var drinkedWater: Double = 0
    
    /// Computed read-only property, returns the total water quantity
    internal var totalWaterQty: Double {
        get {
            return ((self.effort / 30) * 0.2) + (!self.gender ? self.weight * 0.045 : self.weight * 0.033)
        }
    }
    
    /// Store the history of drinks based on timestamp and quantity
    internal var drinks: [NSTimeInterval:Double] = [:]
    
    /// Computed, read-only propriety, returns the remaining quantity of water
    internal var waterLeft: Double {
        get {
            return self.totalWaterQty - self.drinkedWater
        }
    }
    
    //MARK: User Settings
    
    /// User's gender: false for male, true for female
    var gender: Bool = false
    
    /// User's weight in kg
    var weight: Double = 0.0
    
    /// Physical effort, in minutes
    var effort: Double = 0.0
    
    /// Time when user's goes to bed. ***Warning:** Keep in mind that only the time part is relevant, **not** the date*
    var sleepTime: NSDate = NSDate()
    
    /// Time when user's wakes up. ***Warning:** Keep in mind that only the time part is relevant, **not** the date*
    var wakeupTime: NSDate = NSDate()
    
    /// Time when user's goes to lunch. ***Warning:** Keep in mind that only the time part is relevant, **not** the date*
    var lunchTime: NSDate = NSDate()
    
    /// Measurement Unit selection: true for metric, false for Imperial
    var metric: Bool = true
    
    
    //MARK: Other Properties
    
    ///Singleton instance
    static let sharedInstance = WaterLogic()
    
    /// returns the `NSUserDefaults.standardUserDefaults()`. Used in persistent storage methods
    let defaults = NSUserDefaults.standardUserDefaults()
    
    /// Computed, read-only property. Returns the timestamp of the current day, at 00:00 (midnight)
    var midnightTimestamp: NSTimeInterval {
        get {
            return NSDate().timeIntervalMidnight
        }
    }
    
    /// Flag, to tell if it is the first time when the app is launched.
    var firstRun: Bool = true
    
    /// The `WaterLogicProtocol` delegate
    var delegate: WaterLogicProtocol? = nil
    
    /// HealthKit class. By Default use the iOS8 implementation, but when required the code will check if iOS9 exists to execute Water Sample operations
    var hkWaterLogic: HealthKit_iOS8?
    
    /// Contains last timestamp used to save into HealthKit. Usually is the day before the current day
    var hkLastTimeStamp: NSTimeInterval?
    
    var lastInterstitalAdTimestamp: NSTimeInterval?
    
    //MARK: - Class Init
    
    /**
     Initializes a new `WaterLogic` object. `HealthKit` storage is also intialized in this step.
     If it's not the first app launch, the user settings & application state are loaded also.
     - returns: `WaterLogic` object
     */
    private init() {
        print("\(NSDate()): \(type(of: self)):\(#function)")
        
        //HealthKit
        if #available(iOS 9, *) {
            hkWaterLogic = HealthKit_iOS9(waterLogic: self)
        } else {
            hkWaterLogic = HealthKit_iOS8(waterLogic: self)
        }
        
        if self.loadState(false) && self.loadUserSettings(false) {
            self.firstRun = false
        } else {
            //default locale settings
            let locale = NSLocale.currentLocale()
            self.metric = locale.objectForKey(NSLocaleUsesMetricSystem)?.boolValue ?? true
            self.firstRun = true
            
            //init dates
            if let gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) {
                let dateComponents = gregorian.components([.Day, .Month, .Year], fromDate: NSDate())
                dateComponents.minute = 0
                dateComponents.second = 0
                
                dateComponents.hour = 8
                self.wakeupTime = gregorian.dateFromComponents(dateComponents)!
                
                dateComponents.hour = 13
                self.lunchTime = gregorian.dateFromComponents(dateComponents)!
                
                dateComponents.hour = 23
                self.sleepTime = gregorian.dateFromComponents(dateComponents)!
            }
            
            print("Let the bugs come to me")
        }
    }
    
    /**
     Convenience initializer, by specifying the `WaterLogicProtocol` delegate
     - returns: `WaterLogic` object
     */
    private convenience init(withDelegate delegate: WaterLogicProtocol) {
        self.init()
        self.delegate = delegate
    }
    
    
    //MARK: - Application Logic Methods
    
    /**
     Adds `drinkSize` water quantity to `drinkedWater` quantity.
     Also saves the record in `drinks` array and updates the progress in `HealthKit` by calling the HealthKit counterpart `hkUpdateProgress(key: Double)`.
     The key used in the saving process is the current timestamp.
     
     - parameters:
     - endHandler: callback to be executed when the method is done. Keep in mind that HealthKit operations may be still in progress when this is called.
     */
    func drink(endHandler:()->Void) {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        self.drinkedWater = abs(self.drinkedWater + self.drinkSize)
        let key = NSDate().timeIntervalSince1970
        drinks[key] = self.drinkSize
        
        endHandler()
    }
    
    /**
     Undo the previous drink operation. Removes the last record in `drinks` array, updates the `drinkedWater` value and calls the HealthKit counterpart `hkDeleteLastProgressSample(key: Double)`.
     - parameters:
     - endHandler: callback to be executed when the method is done. Keep in mind that HealthKit operations may be still in progress when this is called.
     */
    func undoDrink(endHandler:()->Void) {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        let reversedKeys = self.drinks.keys.sort().reverse()
        if let lastIsFirst = reversedKeys.first {
            
            if lastIsFirst >= self.midnightTimestamp {
                self.drinkedWater = abs(self.drinkedWater - self.drinks[lastIsFirst]!)
                self.drinks.removeValueForKey(lastIsFirst)
            }
            
        }
        endHandler()
    }
    
    /**
     Resets the water quantity when the day is over and calculates the current day's drinked amount of water. Also saved data in HealthKit.
     **Does call `updateRequired`**
     */
    func resetDrinks() {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        if #available(iOS 9, *) {
            //health kit
            let hkWaterLogic = self.hkWaterLogic as! HealthKit_iOS9
            self.hkLastTimeStamp = self.hkLastTimeStamp ?? self.midnightTimestamp
            
            let values = self.drinks.filter { index, value -> Bool in
                return index > self.hkLastTimeStamp && index < self.midnightTimestamp
            }
            
            if values.count > 0 {
                hkWaterLogic.hkUpdateProgress(values) { success, error, timestamp in
                    if success {
                        self.hkLastTimeStamp = timestamp
                    } else {
                        print("Error saving data to HealthKit")
                    }
                }
            }
        }
        
        let values = self.drinks.filter { index, value -> Bool in
            return index >= self.midnightTimestamp
        }
        
        self.drinkedWater = 0.0
        
        for value in values {
            self.drinks[value.0] = value.1
            self.drinkedWater += value.1
        }
        
        if let delegate = self.delegate {
            delegate.updateRequired()
        }
    }
    
    /**
     Changes drink size. This method should be used instead of assigning a direct value to `selectedDrinkSize`
     - parameters:
     - drinkType: the index of the size in `drinkSizeList`
     - returns: true if it was successful, false if the index is out of bounds
     */
    func changeDrinkSize(drinkType: Int) -> Bool {
        if drinkType < self.drinkSizeList.count {
            self.selectedDrinkSize = drinkType
            return true
        }
        return false
    }
    
}
