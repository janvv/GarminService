//
//  GarminService+ServiceUI.swift
//  GarminServiceKitUI
//
//  Created by Jan Wrede on 06/21/2024.
//  Copyright © 2024 Jan Wrede. All rights reserved.
//

import SwiftUI
import LoopKit
import LoopKitUI
import GarminServiceKit

extension GarminService: ServiceUI {
    
    public static var image: UIImage? {
        let image = UIImage(named: "iconsmall.png", in: Bundle(for: GarminServiceTableViewController.self), compatibleWith: nil)
        if image == nil {
            print("Warning: Failed to load 'iconsmall.png' from the bundle.")
        }
        return image
    }

    public static func setupViewController(colorPalette: LoopUIColorPalette, pluginHost: PluginHost) -> SetupUIResult<ServiceViewController, ServiceUI>
    {
        return .userInteractionRequired(ServiceNavigationController(rootViewController: GarminServiceTableViewController(service: GarminService(), for: .create)))
    }
    
    public func settingsViewController(colorPalette: LoopUIColorPalette) -> ServiceViewController
    {
        return ServiceNavigationController(rootViewController: GarminServiceTableViewController(service: self, for: .update))
    }
    
    public func supportMenuItem(supportInfoProvider: SupportInfoProvider, urlHandler: @escaping (URL) -> Void) -> AnyView? {
        return nil
    }
    
    
}
