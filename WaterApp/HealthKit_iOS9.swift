//
//  HealthKit_iOS8.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 10/03/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import HealthKit

/**
 This class replace the current implementation of HealthKit, for iOS 8 capabilities
 */
@available (iOS 9,*)
class HealthKit_iOS9: HealthKit_iOS8 {
    
    //MARK: HealthKit Properties
    
    /// HealthKit water property. Used to write drinked water samples in Health app
    let hkWater = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDietaryWater)!

    
    /**
     Request HealthKit authorization for gender, weight and water. If there is no `HKHealthStore` object then the method will exit silently.
     If the authorisation is successfull, then `healthKitReady()` delegate method will be called.
     */
    override func authorizeHealthKit() {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        guard let hkStore = self.healthStore else { return }
        let hkTypesToWrite = Set([hkWater])
        let hkTypesToRead = Set([hkGender, hkWeight]) //as! Set<HKObjectType>
        
        hkStore.requestAuthorizationToShareTypes(hkTypesToWrite, readTypes: hkTypesToRead) { success, error in
            print("HealthKit Auth Status: \(success)")
            if success {
                if let delegate = self.waterLogic?.delegate {
                    delegate.healthKitReady()
                }
            }
        }
    }

    
    /**
     Converts tuples containing `(timeinterval, value)` in water samples and save them in HealthKit. ***Executed in another queue***
     - parameters:
        - drinks: tuple containing `(timeStamp, waterQuantity)`
        - completionHandler: closure called at the end of saving process.
            - success: if operation was successful or not
            - error: `NSError?` object in case of error
            - timestamp: the most recent timestamp
     */
    func hkUpdateProgress(drinks: [(NSTimeInterval,Double)], completionHandler: (Bool, NSError?, NSTimeInterval) -> Void) {
        dispatch_async(self.hkQueue) {
            print("\(NSDate()): \(self.dynamicType):\(#function)")
            
            let waterUnit = HKUnit.literUnit()
            var samples: [HKQuantitySample] = []
            var lastTimeStamp: NSTimeInterval = 0
            
            for (key, value) in drinks {
                let waterQuantity = HKQuantity(unit: waterUnit, doubleValue: value)
                let date = NSDate(timeIntervalSince1970: key)
                let waterQuantitySample = HKQuantitySample(type: self.hkWater, quantity: waterQuantity, startDate: date, endDate: date)
                samples.append(waterQuantitySample)
                lastTimeStamp = key > lastTimeStamp ? key : lastTimeStamp
            }
            
            self.healthStore?.saveObjects(samples) { success, error in
                completionHandler(success, error, lastTimeStamp)
            }
        }
    }
}