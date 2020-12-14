//
//  NSDateExtension.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 2/9/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation

//MARK: - NSDate Extension
extension NSDate {
    
    /// `string` containing the time in the in the local timezone and format
    var timeToString : String {
        get {
            
            let dateFormatter: NSDateFormatter = NSDateFormatter()
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            
            return NSString(format:"%@", dateFormatter.stringFromDate(self)) as String

        }
    }
    
    /// gets the midnight (00:00) timestamp of the date
    var timeIntervalMidnight: NSTimeInterval {
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let components = calendar?.components([.Day, .Month, .Year], fromDate: self)
        return (calendar?.dateFromComponents(components!)?.timeIntervalSince1970)!
    }
    
    var timeIntervalDifferenceFromMidnight: NSTimeInterval {
        return self.timeIntervalSince1970 - self.timeIntervalMidnight
    }
}

//MARK: - String Extension
extension String {
    
    /// converts a `string` into `date` based on the local timezone and format. Only time component is used.
    var stringToTime : NSDate? {
        get {
            let dateFormatter: NSDateFormatter = NSDateFormatter()
            dateFormatter.timeZone = NSTimeZone.localTimeZone()
            dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
            
            if let date = dateFormatter.dateFromString(self) {
                return date
            } else {
                return nil
            }
        }
    }
}