//
//  StringExtension.swift
//  WaterApp
//
//  Created by cristina on 19/03/16.
//  Copyright © 2016 BogdanCoticopol. All rights reserved.
//

import UIKit

//MARK: - String Extension for localization

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: NSBundle.mainBundle(), value: "", comment: "")
    }
}

