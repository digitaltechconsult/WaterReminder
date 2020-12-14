//
//  WaterLogicProtocol.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 2/23/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation


/**
    Protocol used to interact with other objects (e.g. UI).
*/
protocol WaterLogicProtocol {
    
    /// Called each time when a change in `WaterLogic` object should reflect into the UI
    func updateRequired()
    
    /// Called when `HealthKit` is ready to be used.
    func healthKitReady()
    
}