//
//  GarminServiceKitPlugin.swift
//  GarminServiceKitPlugin
//
//  Created by Jan Wrede on 06/21/2024.
//  Copyright © 2024 Jan Wrede. All rights reserved.
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
