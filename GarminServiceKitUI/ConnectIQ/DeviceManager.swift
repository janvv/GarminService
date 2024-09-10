//
//  DeviceManager.swift
//  Garmin-ExampleApp-Swift
//  1/1/2017
//
//  The following code is a fully-functional port of Garmin's iOS Example App
//  originally written in Objective-C:
//  https://developer.garmin.com/connect-iq/sdk/
//
//  More details on the Connect IQ iOS SDK can be found at:
//  https://developer.garmin.com/connect-iq/developer-tools/ios-sdk-guide/
//
//  MIT License
//
//  Copyright (c) 2017 Doug Williams - dougw@igudo.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import ConnectIQ
import UIKit
import os

let kDevicesFileName = "devices"

protocol DeviceManagerDelegate {
    func devicesChanged()
}

class DeviceManager: NSObject {
    
    var devices = [IQDevice]()
    var delegate: DeviceManagerDelegate?
    private let logger: Logger
    static let sharedInstance = DeviceManager()
   
    private override init() {
        self.logger = Logger(subsystem: "Garmin", category: "DeviceManager")
    }
    
    func handleDeviceSelectionList(devices: [Any?]) {
        if devices.count > 0 {
            logger.info("Received device list with \(devices.count) devices.")
            self.logger.info("Forgetting \(Int(self.devices.count)) known devices.")
            self.devices.removeAll()
            for (index, device) in devices.enumerated() {
                guard let device = device as? IQDevice else { continue }
                self.logger.info("Received device (\(index+1) of \(devices.count): [\(device.uuid), \(device.modelName), \(device.friendlyName)]")
                self.devices.append(device)
            }
            self.saveDevicesToFileSystem()
            self.delegate?.devicesChanged()
        } else {
            self.logger.info("Device list was empty.")
        }
    }
    
    func saveDevicesToFileSystem() {
        self.logger.debug("Saving known devices.")
        
        //let fileManager = FileManager.default
        //let filePath = self.devicesFilePath()
        
        
        //if !NSKeyedArchiver.archiveRootObject(devices, toFile: self.devicesFilePath()) {
        //    print("Failed to save devices file.")
        //}
        //the above code fails, use NSKeyedArchiver.archivedData(withRootObject: <#T##Any#>, requiringSecureCoding: <#T##Bool#>) instead
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: devices, requiringSecureCoding: false)
            try data.write(to: URL(fileURLWithPath: self.devicesFilePath()))
        }
        catch let error {
            self.logger.error("Failed to save devices file with error: \(error)")
        }
        
    }
    
    func restoreDevicesFromFileSystem() {
        do {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: self.devicesFilePath())) {
                if let restoredDevices = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, IQDevice.self], from: data) as? [IQDevice] {
                    // Use restoredDevices array of IQDevice objects
                    if restoredDevices.count > 0 {
                        self.logger.debug("Garmin DeviceManager: Restored saved devices:")
                        for device in restoredDevices {
                            self.logger.debug("\(device)")
                        }
                        self.devices = restoredDevices
                    }
                    else {
                        self.logger.debug("Garmin DeviceManager: No saved devices to restore.")
                        self.devices.removeAll()
                    }
                    self.delegate!.devicesChanged()
                } else {
                    self.logger.warning("Garmin DeviceManager: Failed to unarchive the file as an array of IQDevice objects.")
                }
            } else {
                self.logger.warning("Garmin DeviceManager: Failed to read data from the file.")
            }
        } catch {
            self.logger.error("Error: \(error)")
        }
    }
    
    func devicesFilePath() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let appSupportDirectory = URL(fileURLWithPath: paths[0])
        // list all files in the appSupportDirectory
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: appSupportDirectory.path)
            for file in files {
                self.logger.debug("File: \(file)")
            }
        }
        catch let error {
            self.logger.error("There was an error listing the contents of the directory \(appSupportDirectory) with error: \(error)")
        }
        
        let dirExists = (try? appSupportDirectory.checkResourceIsReachable()) ?? false
        if !dirExists {
            self.logger.debug("Garmin DeviceManager: DeviceManager.devicesFilePath appSupportDirectory \(appSupportDirectory) does not exist, creating... ")
            do {
                try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                self.logger.error("There was an error creating the directory \(appSupportDirectory) with error: \(error)")
            }
        }
        return appSupportDirectory.appendingPathComponent(kDevicesFileName).path
    }
}
