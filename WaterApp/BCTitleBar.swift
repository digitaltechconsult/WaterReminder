//
//  BCTitleBar.swift
//  WaterApp
//
//  Created by Bogdan Coticopol on 07/02/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//
import Foundation
import UIKit

/**
 `UIImage` subclass to be used as title bar: black color, transparency and shadows
*/
class BCTitleBar: UIImageView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.layer.masksToBounds = false;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 1;
        self.layer.shadowOpacity = 0.5;
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.15)
    }
    
}
