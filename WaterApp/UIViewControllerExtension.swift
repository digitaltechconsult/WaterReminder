//
//  AlertExtension.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 26/02/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    /**
        Convenience method to display an alert.
        - parameters:
            - message: the body of the alert
            - title: the title of the alert, default value is `"Error"`
            - actions: array containing the actions. By default the parameter is empty and the alert will have only one action with title `"OK"` that will dismiss the alert
    */
    func displayAlertView(message:String, title:String = LocaleStrings.Error, actions:[UIAlertAction] = []) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        if actions.count > 0 {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(alertAction)
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /**
        Convenience method to add time picker as a keyboard for a `UITextField`. *This method should be refactored to be used in a broader scope.*
        - parameters:
            - caller: the `UITextField` that will use the custom keyboard
            - actionTag: the tag of the picker
            - updateTextFieldSelector: the selector that will be called. In the current implementation, the selector uses the `UIDatePicker.tag` to differenciate between multiple textfields with this custom keyboard
    */
    func inputDatePicker(caller: UITextField, actionTag: Int, updateTextFieldSelector: Selector) {
        
        //create datepicker control
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .Time
        datePicker.minuteInterval = 15
        datePicker.tag = actionTag
        datePicker.addTarget(self, action: updateTextFieldSelector, forControlEvents: UIControlEvents.ValueChanged)
        
        //datepicker color
        let backgroundColor = UIColor.whiteColor()
        let textColor = UIColor(red: 49/255, green: 168/255, blue: 227/255, alpha: 1.0)
        datePicker.setValue(backgroundColor, forKey: "backgroundColor")
        datePicker.setValue(textColor, forKey: "textColor")
        
        //create keyboard view
        let rect = CGRectMake(0, 0, self.view.frame.size.width, datePicker.bounds.size.height)
        let customKeyboard = UIView(frame: rect)
        customKeyboard.backgroundColor = UIColor.whiteColor()
        
        datePicker.center = customKeyboard.center
        customKeyboard.addSubview(datePicker)
        
        caller.inputView = customKeyboard
    }

}