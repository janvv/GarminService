//
//  NightscoutServiceKitPlugin.swift
//  NightscoutServiceKitPlugin
//
//  Created by Darin Krauss on 9/19/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import os.log
import LoopKitUI
import GarminServiceKit
import GarminServiceKitUI

class NightscoutServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = OSLog(category: "GarminServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return GarminService.self
    }

    override init() {
        super.init()
        log.default("Instantiated")
    }
}
