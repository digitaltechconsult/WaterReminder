//
//  WaterLogicNotificationsExtension.swift
//  WaterApp
//
//  Created by BogdanCoticopol on 2/23/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import UIKit

extension WaterLogic {
    
    /**
     Notification messages string constants. To be used when displaying notifications.
     */
    struct NotificationMessages {
        static let Morning = LocaleStrings.NotificationMorning
        static let Night = LocaleStrings.NotificationNight
        static let Lunch = LocaleStrings.NotificationLunch
        static let Default = LocaleStrings.NotificationDefault
        static let HealthApp = LocaleStrings.NotificationHealthApp
    }
    
    /**
     Time duration constants
     */
    struct TimeDuration {
        static let FiftyMinutes: NSTimeInterval = 900
        static let ThirtyMinutes: NSTimeInterval = 1800
        static let OneHour: NSTimeInterval = 3600
        static let OneDay: NSTimeInterval = 86400
    }
    
    //MARK: - Main Notification Methods
    
    /**
     Creates notification alarms of the app. Includes Morning, Lunch, Sleep notifications and also the Default notifications between the previous mentioned moments of day. No notification will be scheduled between Sleep time and Morning time.
     - parameters:
     - days: the number of days to calculate the notifications
     - returns: `[UILocalNotification]` containing all the notifications to be displayed or nil if there are no notification to schedule (e.g. no water left to drink)
     */
    func scheduleNotifications(days: Int) -> [UILocalNotification]? {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        //if too much water and only one day to schedule, then return nil
        if self.waterLeft <= 0 && days <= 1 {
            return nil
        }
        
        var notificationsArray: [UILocalNotification] = []; notificationsArray.reserveCapacity(30) //not sure, but stack overflow says that is faster
        
        var notificationTime: NSTimeInterval = 0
        
        //if no water left, then go to the next day
        let startI = self.waterLeft <= 0 ? 1 : 0
        
        for i in startI...days {
            print("Day: \(i)")
            let day: NSTimeInterval = TimeDuration.OneDay * NSTimeInterval(i)
            
            //morning notification
            let startTime: NSTimeInterval = self.wakeupTime.timeIntervalDifferenceFromMidnight + day
            notificationTime = startTime + self.midnightTimestamp + TimeDuration.FiftyMinutes
            
            if let notification = self.createNotificationWithAlertText(NotificationMessages.Morning, fireDate: notificationTime) {
                notificationsArray.append(notification)
            }
            
            //evening notification
            var endTime: NSTimeInterval = self.sleepTime.timeIntervalDifferenceFromMidnight + day
            //sometimes, you go to bed at 2am, which is the next day, not the same day
            if endTime < startTime {
                endTime += TimeDuration.OneDay //add one day
            }
            
            notificationTime = endTime + self.midnightTimestamp - TimeDuration.FiftyMinutes
            if let notification = self.createNotificationWithAlertText(NotificationMessages.Night, fireDate: notificationTime) {
                notificationsArray.append(notification)
            }
            
            //lunch
            let lunchTime: NSTimeInterval = self.lunchTime.timeIntervalDifferenceFromMidnight + day
            notificationTime = lunchTime + self.midnightTimestamp - TimeDuration.ThirtyMinutes
            if let notification = self.createNotificationWithAlertText(NotificationMessages.Lunch, fireDate: notificationTime) {
                notificationsArray.append(notification)
            }
            
            //first part of the day
            if let notifications = self.createDefaultNotification((startTime + TimeDuration.ThirtyMinutes), endTime: (lunchTime - TimeDuration.OneHour), totalInterval: (endTime - startTime)) {
                notificationsArray.appendContentsOf(notifications)
            }
            
            //second part of the day
            if let notifications = self.createDefaultNotification((lunchTime + TimeDuration.ThirtyMinutes), endTime: (endTime - TimeDuration.ThirtyMinutes), totalInterval: (endTime - startTime)) {
                notificationsArray.appendContentsOf(notifications)
            }
            
        }
        
        return notificationsArray.count > 0 ? notificationsArray : nil
    }
    
    
    /**
     Creates notifications for the default moments in day (not Morning, Lunch or Sleep time)
     - parameters:
     - startTime: timestamp of start period
     - endTime: timestamp of end period
     - totalInterval: the whole period. Keep in mind that totalInterval is not necessarly `endTime - startTime`, but could be bigger
     - returns: `[UILocalNotification]` or nil if there is no notifiation to schedule
     */
    private func createDefaultNotification(startTime: NSTimeInterval, endTime: NSTimeInterval, totalInterval: NSTimeInterval) -> [UILocalNotification]? {
        print("\(NSDate()): \(self.dynamicType):\(#function)")
        
        var notifications: [UILocalNotification] = []
        
        //calculate timeframe
        let t = abs((endTime - startTime)) / abs(totalInterval)
        let w = self.waterLeft * t
        let count = w / self.drinkSize
        let step = abs(endTime - startTime) / count
        let start = self.midnightTimestamp + startTime
        let end = self.midnightTimestamp + endTime
        
        for i in start.stride(to: end, by: step) {
            if let notification = self.createNotificationWithAlertText(NotificationMessages.Default, fireDate: i) {
                notifications.append(notification)
            }
        }
        
        return notifications.count > 0 ? notifications : nil
    }
    
    /**
     Returns a new notification
     - parameters:
     - alertText: the text to be displayed in the notification body
     - fireDate: timestamp when the notification will be raised
     - returns: `UILocalNotification` object or nil if the `fireDate` is less than current date & time
     */
    func createNotificationWithAlertText(alertText: String, fireDate: NSTimeInterval, validateFireDate: Bool = true) -> UILocalNotification? {
        //print("\(NSDate()): \(self.dynamicType):\(#function)")
        //print("Fire date is \(NSDate(timeIntervalSince1970: fireDate)) and current date is \(NSDate())")
        
        let currentTime = NSDate().timeIntervalSince1970 + (validateFireDate ? TimeDuration.FiftyMinutes : 0)
        if fireDate > currentTime {
            let notification = UILocalNotification()
            notification.alertBody = alertText
            notification.soundName = UILocalNotificationDefaultSoundName
            notification.fireDate = NSDate(timeIntervalSince1970: fireDate)
            notification.category = "DRINK_CATEGORY"
            //            print("Notification created: '\(notification.alertBody!)', for date \(notification.fireDate!)")
            return notification
        }
        
        return nil
    }
    
    
    //MARK: - Other Notifiaction Methods
    
    /**
     Gets the next notifiation in queue
     -returns: `UILocalNotification` object if there are notifications in queue or nil otherwise
     */
    func nextNotification() -> UILocalNotification? {
        if let notifications = UIApplication.sharedApplication().scheduledLocalNotifications {
            let sortedNotifications = notifications.sort { n1, n2 -> Bool in
                return n1.fireDate?.timeIntervalSince1970 < n2.fireDate?.timeIntervalSince1970
            }
            return  sortedNotifications.first
        }
        return nil
    }
    
    /**
     Postpone already displayed notification to be fired at a later date.
     If there is another notification to be fired in a period of time less than `timeInterval` value then the notification will be not postponed.
     - parameters:
     - notification: local notification to be postponed
     - timeInterval: the interval to add to `notification.fireDate`. Default value is `TimeDuration.FiftyMinutes` secondes
     */
    func postponeNotification(notifcation:UILocalNotification, timeInterval:NSTimeInterval = TimeDuration.FiftyMinutes) {
        let newNotification = notifcation
        let newInterval = NSDate().timeIntervalSince1970 + timeInterval
        newNotification.fireDate = NSDate(timeIntervalSince1970: newInterval)
        
        //check if next notification is triggered in less than 15 minutes; if yes, don't postpone it
        if let nextNotificationInQueue = self.nextNotification() {
            if abs(nextNotificationInQueue.fireDate!.timeIntervalSince1970 - newInterval) > timeInterval {
                UIApplication.sharedApplication().scheduleLocalNotification(newNotification)
                print("Notification successfully postponed")
            } else {
                print("The time is too short")
            }
        } else { //no notifications left, create new one
            UIApplication.sharedApplication().scheduleLocalNotification(newNotification)
            print("Notification successfully postponed (there are no other notifications in queue)")
        }
    }
    
    
}