//
//  Constants.swift
//  GarminServiceKitUI
//
//  Created by Jan on 22.07.24.
//  Copyright © 2024 LoopKit Authors. All rights reserved.
//

import Foundation

//The url scheme is what garmin connect will use to open this application, we need to specify the URL scheme value (CFBundleURLSchemes key) which is under the CFBundleURLTypes in the plist file. This value is currently set to LoopGarmin
let ReturnURLScheme = "LoopGarmin" // must match project settings Project Settings -> Info -> URL Types

extension Notification.Name {
    static let didReceiveURLNotification = Notification.Name("didReceiveURL")
}
