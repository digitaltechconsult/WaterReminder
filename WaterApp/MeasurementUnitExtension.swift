//
//  MeasurementUnitExtension.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 2/23/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation

extension Double {
    
    //MARK: Weight
    
    /// Converts kg in pounds (lbs)
    var metricToImperialWeight: Double {
        get {
            return self * 2.2046
        }
    }
    
    /// Converts pounds in kg
    var imperialToMetricWeight: Double {
        get {
            return self * 0.4535
        }
        
    }
    
    //MARK: Volume
    
    //TODO: There is a difference between Imperial ounces and US ounces
    
    /// Converts liters in Imperial Ounces
    var metricToImperialVolume: Double {
        get {         
            return self * 35.1951
        }
    }
    
    /// Converts Imperial Ounces in liters
    var imperialToMetricVolume: Double {
        get {
            return self * 0.0284
        }
    }
}
