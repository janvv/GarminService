//
//  Constants.swift
//  GarminServiceKitUI
//
//  Created by Jan on 22.07.24.
//  Copyright © 2024 LoopKit Authors. All rights reserved.
//

import Foundation

//The url scheme is what garmin connect will use to open this application, we need to specify the URL scheme value (CFBundleURLSchemes key) which is under the CFBundleURLTypes in the plist file. This value is currently set to LoopGarmin
let ReturnURLScheme = "Loop" // must match project settings Project Settings -> Info -> URL Types
//CFBundleURLSchemes key value is $(URL_SCHEME_NAME) which is set in Loop.xconfig to URL_SCHEME_NAME = $(MAIN_APP_DISPLAY_NAME) and $(MAIN_APP_DISPLAY_NAME) is set to Loop

extension Notification.Name {
    static let didReceiveURLNotification = Notification.Name("didReceiveURL")
}
