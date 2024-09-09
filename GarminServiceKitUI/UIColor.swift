//
//  UIColor.swift
//  NightscoutServiceKitUI
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import UIKit

extension UIColor {

    @nonobjc static let delete = UIColor.HIGRedColor()

    // MARK: - HIG colors
    // See: https://developer.apple.com/ios/human-interface-guidelines/visual-design/color/

    private static func HIGRedColor() -> UIColor {
        return UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)
    }

}
