//
//  String + Extension.swift
//  SmartCamMasterApp
//
//  Created by Денис Хафизов on 22.04.2024.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "\(self) could not be found in Locolizable")
    }
}
