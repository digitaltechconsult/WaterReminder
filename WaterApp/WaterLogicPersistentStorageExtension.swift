//
//  WaterLogicPersistentStorageExtension.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 2/23/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
extension WaterLogic {
    //MARK: - Persistent Storage Operations
    
    /**
    Constants used in saving or loading application state
    */
    struct PersistentStorageConstants {
        static let kDrinkedWater = "WaterApp_drinkedWater"
        static let kSelectedDrinkSize = "WaterApp_drinkSize"
        static let kDrinks = "WaterApp_drinks"
        static let kHKLastTimestamp = "WaterApp_hkLastTimestamp"
        static let kLastAdTimestamp = "WaterApp_465TimeStamp"
    }
    
    /**
     Constants used in saving or loading user settings
     */
    struct UserSettings {
        static let kUserGender = "WaterApp_gender"
        static let kUserWeight = "WaterApp_weight"
        static let kUserFitness = "WaterApp_effort"
        static let kUserSleepTime = "WaterApp_sleepTime"
        static let kUserWakeupTime = "WaterApp_wakeupTime"
        static let kUserLunchTime = "WaterApp_lunchTime"
        static let kUserMeasurementSystem = "WaterApp_MeasurementSystem"
    }
    
    /**
     Loads the application state, meaning: `drinkedWater`, `selectedDrinkSize`, `drinks` and `hkDrinks`.
     After all object are loaded, calls the delgate method `updateRequired` in order to allow the UI to be refreshed if needed.
     - parameters:
        - sendUpdateRequired: by default true, allow calling the `updateRequired` delegate method
     - returns: if one object fails to be loaded, the method will return false
     */
    func loadState(sendUpdateRequired: Bool = true) -> Bool {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        guard let drinkedWater = defaults.objectForKey(PersistentStorageConstants.kDrinkedWater) as? Double,
            let drinkSize = defaults.objectForKey(PersistentStorageConstants.kSelectedDrinkSize) as? Int,
            let drinksArchived = defaults.objectForKey(PersistentStorageConstants.kDrinks) as? NSData
            else { return false }
        
        self.drinkedWater = drinkedWater
        self.selectedDrinkSize = drinkSize
        
        if let drinkList = NSKeyedUnarchiver.unarchiveObjectWithData(drinksArchived) as? [NSTimeInterval:Double] {
            self.drinks = drinkList
        } else {
            return false
        }
        
        if #available(iOS 9,*) {
            if let hkLastTimeStamp = defaults.objectForKey(PersistentStorageConstants.kHKLastTimestamp) as? Double {
                self.hkLastTimeStamp = hkLastTimeStamp
            } else {
                return false
            }
        }
        
        //load last ad timestamp 
        if let timestamp = defaults.objectForKey(PersistentStorageConstants.kLastAdTimestamp) as? Double {
            self.lastInterstitalAdTimestamp = timestamp
        }
        
        if sendUpdateRequired {
            if let delegate = self.delegate {
                delegate.updateRequired()
            }
        }
        
        return true
    }
    
    /**
     Loads any other properties that were not loaded in `loadState() -> Bool`, mostly user settings.
     After all object are loaded, calls the delgate method `updateRequired` in order to allow the UI to be refreshed if needed.
     - parameters:
        - sendUpdateRequired: by default true, allow calling the `updateRequired` delegate method
     - returns: if one object fails to be loaded, the method will return false
     */
    func loadUserSettings(sendUpdateRequired: Bool = true) -> Bool {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        guard let gender = defaults.objectForKey(UserSettings.kUserGender) as? Bool,
            let weight = defaults.objectForKey(UserSettings.kUserWeight) as? Double,
            let effort = defaults.objectForKey(UserSettings.kUserFitness) as? Double,
            let sleepTime = defaults.objectForKey(UserSettings.kUserSleepTime) as? NSDate,
            let wakeupTime = defaults.objectForKey(UserSettings.kUserWakeupTime) as? NSDate,
            let lunchTime = defaults.objectForKey(UserSettings.kUserLunchTime) as? NSDate,
            let metricSystem = defaults.objectForKey(UserSettings.kUserMeasurementSystem) as? Bool
            else { return false }
        
        self.gender = gender
        self.metric = metricSystem
        self.weight = weight
        self.effort = effort
        self.wakeupTime = wakeupTime
        self.lunchTime = lunchTime
        self.sleepTime = sleepTime
        
        if sendUpdateRequired {
            if let delegate = self.delegate {
                delegate.updateRequired()
            }
        }
        
        
        return true
    }
    
    /**
     Saves the states of the app.
     - returns: true if the save operation is successfully, false otherwise
     */
    func saveState() -> Bool {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        defaults.setObject(self.drinkedWater, forKey: PersistentStorageConstants.kDrinkedWater)
        defaults.setObject(self.selectedDrinkSize, forKey: PersistentStorageConstants.kSelectedDrinkSize)
        
        if let timestamp = self.lastInterstitalAdTimestamp {
            defaults.setObject(timestamp, forKey: PersistentStorageConstants.kLastAdTimestamp)
        }
        
        let drinksArchive = NSKeyedArchiver.archivedDataWithRootObject(self.drinks)
        defaults.setObject(drinksArchive, forKey: PersistentStorageConstants.kDrinks)
        
        if #available (iOS 9, *) {
            defaults.setObject(self.hkLastTimeStamp!, forKey: PersistentStorageConstants.kHKLastTimestamp)
        }
        
        let result = defaults.synchronize()
        return result
    }
    
    /**
     Saves the user settings.
     - returns: true if the save operation is successfully, false otherwise
     */
    func saveUserSettings() -> Bool {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        defaults.setObject(self.gender, forKey: UserSettings.kUserGender)
        defaults.setObject(self.weight, forKey: UserSettings.kUserWeight)
        defaults.setObject(self.effort, forKey: UserSettings.kUserFitness)
        defaults.setObject(self.lunchTime, forKey: UserSettings.kUserLunchTime)
        defaults.setObject(self.wakeupTime, forKey: UserSettings.kUserWakeupTime)
        defaults.setObject(self.sleepTime, forKey: UserSettings.kUserSleepTime)
        defaults.setObject(self.metric, forKey: UserSettings.kUserMeasurementSystem)
        
        let result = defaults.synchronize()
        return result
    }
    
}
