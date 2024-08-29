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

class GarminServiceKitPlugin: NSObject, ServiceUIPlugin {
    private let log = Logger(subsystem: "Garmin", category: "GarminServiceKitPlugin")

    public var serviceType: ServiceUI.Type? {
        return GarminService.self
    }

    override init() {
        super.init()
        log.info("Instantiated")
    }
}
