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
@available (iOS 8,*)
class HealthKit_iOS8 {
    
    //MARK: HealthKit Properties
    
    /// Stores the only instance of `HealthStore` used to do all the HealthKit operations
    var healthStore: HKHealthStore? = nil
    
    /// HealthKit gender property. Used to read the gender from Health app
    let hkGender = HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!
    /// HealthKit weight property. Used to read the weight from Health app
    let hkWeight = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)!
    
    /// Convenience property, to get the `global queue`, with `background priority`
    let hkQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)

    /// Weak reference to WaterLogic. Used to keep code from the previous WaterLogic HealthKit Extension
    weak var waterLogic: WaterLogic!
    
    /**
     Inits the `self.healhStore`. If successfull, calls `authorizeHealthKit()` method
     */
    required init(waterLogic: WaterLogic) {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        self.waterLogic = waterLogic
        
        if HKHealthStore.isHealthDataAvailable() {
            
            self.healthStore = HKHealthStore()
            if let _ = self.healthStore {
                self.authorizeHealthKit()
            }
        }
    }
    
    
    /**
     Request HealthKit authorization for gender, weight and water. If there is no `HKHealthStore` object then the method will exit silently.
     If the authorisation is successfull, then `healthKitReady()` delegate method will be called.
     */
    func authorizeHealthKit() {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        guard let hkStore = self.healthStore else { return }
        
        let hkTypesToRead = Set([hkGender, hkWeight]) //as! Set<HKObjectType>
    
        hkStore.requestAuthorizationToShareTypes(nil, readTypes: hkTypesToRead) { success, error in
            print("HealthKit Auth Status: \(success)")
            if success {
                if let delegate = self.waterLogic.delegate {
                    delegate.healthKitReady()
                }
            }
        }
    }
    
    /**
     Retrieves the gender and weight from the Health app. Also calls the `updateRequired` delegate method.
     */
    func hkRetrieveUserSettings() {
        dispatch_async(self.hkQueue) {
            print("\(NSDate()): \(self.dynamicType):\(#function)")
            
            
            do {
                //gender
                if let gender: HKBiologicalSexObject = try self.healthStore?.biologicalSex() {
                    switch(gender.biologicalSex) {
                    case .Female: self.waterLogic.gender = true
                    case .Male, .Other: self.waterLogic.gender = false
                    case .NotSet: print("Gender not set")
                    }
                    if let delegate = self.waterLogic.delegate {
                        delegate.updateRequired()
                    }
                }
                
            } catch(let err) {
                print("Error getting user settings: \((err as NSError).description)")
            }
            
            
            //weight
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let hkWeightQuery = HKSampleQuery(sampleType: self.hkWeight, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
                if let lastSampleValue = (results?.first) as? HKQuantitySample {
                    self.waterLogic.weight = lastSampleValue.quantity.doubleValueForUnit(HKUnit.gramUnit()) * 0.001
                    if let delegate = self.waterLogic.delegate {
                        delegate.updateRequired()
                    }
                }
            }
            self.healthStore?.executeQuery(hkWeightQuery)
            
        }
    }
}