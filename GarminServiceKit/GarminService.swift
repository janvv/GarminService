//
//  GarminService.swift
//  GarminService
//
//  Created by Jan Wrede on 06/21/2024.
//  Copyright © 2024 Jan Wrede. All rights reserved.
//

import os.log
import LoopKit
import HealthKit
import ConnectIQ
import os
public enum GarminServiceError: Error {
    case incompatibleTherapySettings
    case missingCredentials
}

public final class GarminService: Service {
    public weak var stateDelegate: StatefulPluggableDelegate?
    
    public static var pluginIdentifier = "GarminService"
    //public static let serviceIdentifier = "GarminService"
   
    public var customerToken: String?


    public static let localizedTitle = LocalizedString("Garmin", comment: "The title of the Garmin service")
    
    public weak var serviceDelegate: ServiceDelegate?

    public var isOnboarded: Bool
    
    public var app: IQApp?
    
    private let logger : Logger
    
    
    public init() {
        self.isOnboarded = true
        self.logger = Logger(subsystem: "Garmin", category: "GarminService")
        self.logger.info("GarminService.init")
        restoreGarminDevice()
    }
    
    public required init?(rawState: RawStateValue) {
        self.isOnboarded = rawState["isOnboarded"] as? Bool ?? true   // Backwards compatibility
        self.logger = Logger(subsystem: "Garmin", category: "GarminService")
        self.logger.info("GarminService.init (raw state)")
        restoreGarminDevice()
    }
    
    public var rawState: RawStateValue {
        return [
            "isOnboarded": isOnboarded,
        ]
    }
    
    public func completeCreate() {
        self.logger.info("GarminService.completeCreate")
        //try! KeychainManager().setLogglyCustomerToken(customerToken)
        //createClient()
    }

    public func completeUpdate() {
        self.logger.info("GarminService.completeUpdate")
        //try! KeychainManager().setLogglyCustomerToken(customerToken)
        //createClient()
        //serviceDelegate?.serviceDidUpdateState(self)
        stateDelegate?.pluginDidUpdateState(self)
    }

    public func completeDelete() {
        //try! KeychainManager().setLogglyCustomerToken()
        self.logger.info("GarminService.completeDelete")
        //delete selected device from user defaults
        self.removeGarminDeviceFromStorage()
        self.logger.info( "GarminService.completeDelete - device removed from storage")
        
        //serviceDelegate?.serviceWantsDeletion(self)
        stateDelegate?.pluginWantsDeletion(self)
    }
    
    private func removeGarminDeviceFromStorage() {
        UserDefaults.standard.removeObject(forKey: "activeGarminDeviceUUID")
    }
    private func restoreGarminDevice() {
        //restore previously active device using the uuid from stored user defaults
        if let savedUUIDString = UserDefaults.standard.string(forKey: "activeGarminDeviceUUID"),
           let savedUUID = UUID(uuidString: savedUUIDString) {
            logger.info("Restoring active garmin device from saved UUID: \(savedUUID)")
            let device = IQDevice(id: savedUUID, modelName: "", friendlyName: "")
            self.setActiveGarminDevice(device)
            
        } else {
            logger.info("No Garmin device information found.")
        }
    }
    
    public func setActiveGarminDevice(_ device: IQDevice?) {

        //if there was an old device, deregister it
        if let oldDevice = self.app?.device {
            self.logger.info("Deregistering for device events for \(oldDevice)")
            ConnectIQ.sharedInstance().unregister(forDeviceEvents: self.app?.device, delegate: nil)
            
            //remove from UserDefaults
            self.app = nil
            UserDefaults.standard.removeObject(forKey: "activeGarminDeviceUUID")
        }
        
        self.logger.info("Setting active garmin device to \(device ?? nil)")
        if let device = device {
            //TODO: Check if app is installed
            self.app = IQApp(uuid: UUID(uuidString: "4e93029c-304d-45c1-8732-901fb8162887"), store: UUID(), device: device)
            // Save the UUID of the device to UserDefaults (or a similar persistent store)
            UserDefaults.standard.set(device.uuid.uuidString, forKey: "activeGarminDeviceUUID")
            
            /*If we don't register the device, sensind messages fails with DeviceNotAvailable
             We pass nil because we are not actively monitoring device status yet
             From the documentation: A companion app must register to receive device events before calling methods that operate on devices or apps, such as `getDeviceStatus:` or `sendMessage:toApp:progress:completion:`.
             */
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: nil)
        }
        
        //send with 5 second delay to allow for bluetooth connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {self.sendMostRecentGlucose()}
    }


    public func sendMessage(_ message: [String: Any]) {
        //We need to send a message to the garmin device using the ConnectIQ framework. We create a message object with the message data and the app object. We then send the message using the ConnectIQ send message method. We also register for the message progress and completion events
        if let app = self.app {
            self.logger.info("Sending message: \(message)")
            ConnectIQ.sharedInstance().sendMessage(message, to: app, progress: nil, completion: {(result: IQSendMessageResult) -> Void in
                self.logger.info("Sent message result: \(NSStringFromSendMessageResult(result))")
            })}
        else {
            self.logger.info("No garmin aplication set, skipping message")
        }
    }

    private func sendMostRecentGlucose(){
        let healthStore = HKHealthStore()
        let glucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
        let glucoseQuery = HKSampleQuery(sampleType: glucoseType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { (query, samples, error) in
            if let samples = samples as? [HKQuantitySample] {
                if let sample = samples.first {
                    let glucose = sample.quantity.doubleValue(for: HKUnit(from: "mg/dL"))
                    let date = sample.startDate
                    let trend = sample.trend?.rawValue ?? -1
                    let message = ["glucose": glucose, "trend": trend, "timestamp": Int(date.timeIntervalSince1970)] as [String : Any]
                    
                    self.logger.debug("Sending most recent glucose: \(glucose) Trend: \(trend) Date: \(date)")
                    self.sendMessage(message)
                }
            }
        }
        healthStore.execute(glucoseQuery)
    }
}


extension GarminService: RemoteDataService {
    public func remoteNotificationWasReceived(_ notification: [String : AnyObject]) async throws {
        return
    }
    
    public func uploadAlertData(_ stored: [LoopKit.SyncAlertObject], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadCarbData(created: [LoopKit.SyncCarbObject], updated: [LoopKit.SyncCarbObject], deleted: [LoopKit.SyncCarbObject], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadTemporaryOverrideData(updated: [LoopKit.TemporaryScheduleOverride], deleted: [LoopKit.TemporaryScheduleOverride], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadDoseData(created: [LoopKit.DoseEntry], deleted: [LoopKit.DoseEntry], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadDosingDecisionData(_ stored: [LoopKit.StoredDosingDecision], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadGlucoseData(_ stored: [LoopKit.StoredGlucoseSample], completion: @escaping (Result<Bool, any Error>) -> Void) {
        
        if !stored.isEmpty{
            //skip outdated samples
            let sortedSamples = stored.sorted(by: { $0.startDate > $1.startDate })
            let mostRecentSample = sortedSamples.first!
            if mostRecentSample.startDate.timeIntervalSinceNow <= 10*60 {
                let message = ["glucose": mostRecentSample.quantity.doubleValue(for: HKUnit(from: "mg/dL")),
                               "trend": mostRecentSample.trend?.rawValue ?? -1,
                               "timestamp": Int(mostRecentSample.startDate.timeIntervalSince1970)] as [String : Any]
                self.sendMessage(message)
            } else {
                self.logger.error("Glucose data is more than 60 seconds old, not sending")
            }
        }
        completion(.success(true))
        return
    }
    
    
    public func uploadCgmEventData(_ stored: [PersistedCgmEvent], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadPumpEventData(_ stored: [LoopKit.PersistedPumpEvent], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public func uploadSettingsData(_ stored: [LoopKit.StoredSettings], completion: @escaping (Result<Bool, any Error>) -> Void) {
        completion(.success(true))
        return
    }
    
    public var glucoseDataLimit: Int? {return 1000}
}

