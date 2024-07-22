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

let kDevicesFileName = "devices"

protocol DeviceManagerDelegate {
    func devicesChanged()
}

class DeviceManager: NSObject {
    
    var devices = [IQDevice]()
    var delegate: DeviceManagerDelegate?
    
    static let sharedInstance = DeviceManager()
   
    private override init() {
        // no op
    }
    
    func handleOpenURL(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        guard let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String else {
//            print("handleOpenURL: Source application value was nil, expecting \(IQGCMBundle); disregarind open request, likely not for us.")
//            return false
//        }
        var sourceApplication = IQGCMBundle
        if (url.scheme! == ReturnURLScheme) && (sourceApplication == IQGCMBundle) {
            
            let devices = ConnectIQ.sharedInstance().parseDeviceSelectionResponse(from: url)
            dump(devices)
            if let devices = devices, devices.count > 0 {
                NSLog("Forgetting \(Int(self.devices.count)) known devices.")
                self.devices.removeAll()
                for (index, device) in devices.enumerated() {
                    guard let device = device as? IQDevice else { continue }
                    NSLog("Received device (\(index+1) of \(devices.count): [\(device.uuid), \(device.modelName), \(device.friendlyName)]")
                    self.devices.append(device)
                    NSLog("status>>> \(ConnectIQ.sharedInstance().getDeviceStatus(device).rawValue)")
                }
                self.saveDevicesToFileSystem()
                self.delegate?.devicesChanged()
                return true
            }
        }
        return false
    }
    
    func saveDevicesToFileSystem() {
        NSLog("Saving known devices.")
        
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
            NSLog("Failed to save devices file with error: \(error)")
        }
        
    }
    
    func restoreDevicesFromFileSystem() {
        do {
            if let data = try? Data(contentsOf: URL(fileURLWithPath: self.devicesFilePath())) {
                if let restoredDevices = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, IQDevice.self], from: data) as? [IQDevice] {
                    // Use restoredDevices array of IQDevice objects
                    if restoredDevices.count > 0 {
                        NSLog("Garmin DeviceManager: Restored saved devices:")
                        for device in restoredDevices {
                            NSLog("\(device)")
                        }
                        self.devices = restoredDevices
                    }
                    else {
                        NSLog("Garmin DeviceManager: No saved devices to restore.")
                        self.devices.removeAll()
                    }
                    //self.delegate!.devicesChanged()
                } else {
                    NSLog("Garmin DeviceManager: Failed to unarchive the file as an array of IQDevice objects.")
                }
            } else {
                NSLog("Garmin DeviceManager: Failed to read data from the file.")
            }
        } catch {
            NSLog("Error: \(error)")
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
                print("File: \(file)")
            }
        }
        catch let error {
            NSLog("There was an error listing the contents of the directory \(appSupportDirectory) with error: \(error)")
        }
        
        let dirExists = (try? appSupportDirectory.checkResourceIsReachable()) ?? false
        if !dirExists {
            NSLog("Garmin DeviceManager: DeviceManager.devicesFilePath appSupportDirectory \(appSupportDirectory) does not exist, creating... ")
            do {
                try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            catch let error {
                NSLog("There was an error creating the directory \(appSupportDirectory) with error: \(error)")
            }
        }
        return appSupportDirectory.appendingPathComponent(kDevicesFileName).path
    }
}
