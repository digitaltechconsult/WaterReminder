//
//  SettingsViewController.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 30/01/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import UIKit
import iAd
import StoreKit

class SettingsViewController: WaterViewController {
    
    //UI
    @IBOutlet weak var genderInput: UISegmentedControl!
    @IBOutlet weak var metricInput: UISegmentedControl!
    @IBOutlet weak var weightInput: UITextField!
    @IBOutlet weak var effortInput: UITextField!
    @IBOutlet weak var lunchTimeInput: UITextField!
    @IBOutlet weak var wakeupTimeInput: UITextField!
    @IBOutlet weak var sleepTimeInput: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleBar: BCTitleBar!
    @IBOutlet weak var weightLabel: UILabel!
    
    
    @IBAction func next(sender: UIButton) {
        exitSettingsScreen()
    }
    
    @IBAction func back(sender: UIButton) {
        exitSettingsScreen()
    }
    
    @IBAction func unitSystemChanged(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1{
            weightLabel.text = LocaleStrings.WeightLbs
            waterLogic.metric = false
        }
        else{
            weightLabel.text = LocaleStrings.WeightKg
            waterLogic.metric = true
        }
        
        if "\(waterLogic.weight)" == "0.0" && weightInput.text != ""{
            waterLogic.weight = Double(weightInput.text!)!
        }
        weightInput.text = "\(round(waterLogic.metric ? waterLogic.weight : waterLogic.weight.metricToImperialWeight))"
    }
    
    /// The current selected field
    var currentTextfield:UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.hidden = true
        
        if waterLogic.firstRun{
            nextButton.hidden = false
            backButton.hidden = true
        }
        
        //custom keyboards
        self.inputDatePicker(self.lunchTimeInput, actionTag: 1, updateTextFieldSelector: #selector(SettingsViewController.updateTextField(_:)))
        self.inputDatePicker(self.wakeupTimeInput, actionTag: 2, updateTextFieldSelector: #selector(SettingsViewController.updateTextField(_:)))
        self.inputDatePicker(self.sleepTimeInput, actionTag: 3, updateTextFieldSelector: #selector(SettingsViewController.updateTextField(_:)))
        
        //tap object
        let touch = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.dismissFirstResponder))
        self.view.addGestureRecognizer(touch)
        
        self.updateUI()
        self.weightLabel.text = self.waterLogic.metric ? LocaleStrings.WeightKg : LocaleStrings.WeightLbs
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsViewController.keyboardWasShown(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SettingsViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        let hideKeyboardRecognizer = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.hideKeyboard))
        self.view.addGestureRecognizer(hideKeyboardRecognizer)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        super.viewWillDisappear(animated)
    }
    
    /// Updates the UI with `WaterLogic` object values
    func updateUI() {
        dispatch_async(dispatch_get_main_queue()) {
            self.genderInput.selectedSegmentIndex = self.waterLogic.gender ? 1 : 0
            self.metricInput.selectedSegmentIndex = self.waterLogic.metric ? 0 : 1
            let weight = self.waterLogic.metric ? self.waterLogic.weight : self.waterLogic.weight.metricToImperialWeight
            self.weightInput.text = "\(round(weight))"
            self.effortInput.text = "\(self.waterLogic.effort)"
            self.sleepTimeInput.text = "\(self.waterLogic.sleepTime.timeToString)"
            self.wakeupTimeInput.text = "\(self.waterLogic.wakeupTime.timeToString)"
            self.lunchTimeInput.text = "\(self.waterLogic.lunchTime.timeToString)"
        }
    }
    
    /// Perform field validations, save user settings and dismiss the current view controller
    func exitSettingsScreen() {
        self.waterLogic.gender = self.genderInput.selectedSegmentIndex == 0 ? false : true
        self.waterLogic.metric = self.metricInput.selectedSegmentIndex == 0 ? true : false
        
        if let text = self.weightInput.text, weight = Double(text) {
            self.waterLogic.weight = self.waterLogic.metric ? weight : weight.imperialToMetricWeight
        } else {
            //textfield does not contains a number
            self.weightInput.text = "0.0"
            self.waterLogic.weight = 0.0
        }
        
        if let text = self.effortInput.text, effort = Double(text) {
            self.waterLogic.effort = effort
        } else {
            //textfield does not contains a number
            self.effortInput.text = "0.0"
            self.waterLogic.effort = 0.0
        }
        
        if !validateFields() || !self.validateTimeFields() {
            return
        }
        
        if waterLogic.saveUserSettings() {
            waterLogic.firstRun = false
            appDelegate.scheduleNotifications {
                dispatch_async(dispatch_get_main_queue()) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.trackEvent("ExitSettingsScreen")
                }
            }
        }
    }
    
    /// dismiss the keyboard
    func dismissFirstResponder() {
        self.view.endEditing(true)
    }
    
    /**
     Updates the time text fields. The update is done based on `tag` property of `UIDatePicker`
     - parameters:
     - sender: the `UIDatePicker` used to retrieve the time from.
     */
    func updateTextField(sender: UIDatePicker) {
        
        switch sender.tag {
        case 1:
            self.waterLogic.lunchTime = sender.date
            self.lunchTimeInput.text = self.waterLogic.lunchTime.timeToString
        case 2:
            self.waterLogic.wakeupTime = sender.date
            self.wakeupTimeInput.text = self.waterLogic.wakeupTime.timeToString
        case 3:
            self.waterLogic.sleepTime = sender.date
            self.sleepTimeInput.text = self.waterLogic.sleepTime.timeToString
        default:
            print("\(#function): Unkonwn tag received \(sender.tag)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - textField validations
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if (textField == weightInput || textField == effortInput ) && textField.text == "0.0"{
            textField.text = ""
        }
        
        if (textField == wakeupTimeInput || textField == lunchTimeInput || textField == sleepTimeInput) {
            if let datePicker = textField.inputView?.subviews[0] as? UIDatePicker, let date = textField.text?.stringToTime {
                datePicker.date = date
            }
        }
        
        currentTextfield = textField
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        if (textField == weightInput || textField == effortInput) && string != "" && strlen(textField.text!) > 2 {
            return false
        }
        return true
    }
    
    func validateFields() -> Bool{
        if self.waterLogic.totalWaterQty <= 0 || self.waterLogic.totalWaterQty > 8 || self.waterLogic.weight <= 1 {
            self.displayAlertView(LocaleStrings.FillWeightAndWorkout)
            return false
        }
        return true
    }
    
    func validateTimeFields() -> Bool {
        
        guard let startTime = self.wakeupTimeInput.text?.stringToTime?.timeIntervalSince1970,
            let _ = self.wakeupTimeInput.text?.stringToTime?.timeIntervalSince1970,
            let endTime = self.sleepTimeInput.text?.stringToTime?.timeIntervalSince1970 else {
                self.displayAlertView(LocaleStrings.ChooseValidDate)
                return false
        }
        
        if abs(endTime - startTime) < 10800 {
            self.displayAlertView(LocaleStrings.AwakeLessThan3Hours)
            return false
        }
        
        return true
    }
    
    // MARK: - Keyboard avoidance functions
    func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func keyboardWasShown(notification: NSNotification) {
        let userInfo = notification.userInfo
        let keyboardSize = (userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue().size ?? CGSizeZero
        var y = wakeupTimeInput.frame.origin.y
        
        if currentTextfield?.frame.origin.y < wakeupTimeInput.frame.origin.y{
            y = weightInput.frame.origin.y
        }
        
        if let textField = currentTextfield {
            let textFieldY = textField.frame.origin.y + titleBar.frame.height + textField.frame.height
            
            if textFieldY > view.frame.height - keyboardSize.height {
                let offsetY = y - 45
                scrollView.layoutSubviews()
                scrollView.setContentOffset(CGPoint(x: 0.0, y: offsetY), animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        scrollView.setContentOffset(CGPointZero, animated: true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }
    
    //MARK: WaterLogicProtocol
    override func updateRequired() {
        self.updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.trackScreenName("SettingsScreen")
    }
}
