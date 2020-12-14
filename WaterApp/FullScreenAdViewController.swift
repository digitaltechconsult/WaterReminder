//
//  FullScreenAdViewController.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 01/04/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import UIKit

class FullScreenAdViewController: WaterViewController, ALAdDisplayDelegate  {

    @IBOutlet weak var sponsorMessage: UILabel!
    @IBOutlet weak var donateMessage: UITextView!
    
    var counter: Int = 12
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if waterLogic.lastInterstitalAdTimestamp != nil {
            counter = 2
            donateMessage.hidden = true
        }
        
        sponsorMessage.text = "Message from our sponsor" + "\n" + "in \(counter) seconds"
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(timerTrigger), userInfo: nil, repeats: true)
        ALInterstitialAd.shared().adDisplayDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func timerTrigger() {
        if counter <= 1 {
            timer?.invalidate()
            
            //first time just display the notice
            if waterLogic.lastInterstitalAdTimestamp != nil {
                ALInterstitialAd.show()
            } else {
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            
            
        } else {
            counter -= 1
            sponsorMessage.text = "Message from our sponsor" + "\n" + "in \(counter) seconds"
        }
    }

    
    //MARK: - ALAdDisplayDelegate Methods
    func ad(ad: ALAd, wasHiddenIn view: UIView) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func ad(ad: ALAd, wasClickedIn view: UIView) {
        self.waterLogic.saveState()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func ad(ad: ALAd, wasDisplayedIn view: UIView) {
        if let timer = self.timer {
            timer.invalidate()
        }
        self.sponsorMessage.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.trackScreenName("Ad Screen")
    }
    
}
