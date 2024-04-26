//
//  UIImage + Extension.swift
//  SmartCamMasterApp
//
//  Created by Денис Хафизов on 17.04.2024.
//

import UIKit

extension UIImage {
    var brightness: Double {
        return (self.cgImage?.brightness)!
    }
}


