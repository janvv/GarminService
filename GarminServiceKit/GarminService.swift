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
    
    private func restoreGarminDevice() {
        //restore previously active device using the uuid from stored user defaults
        if let savedUUIDString = UserDefaults.standard.string(forKey: "activeGarminDeviceUUID"),
           let savedUUID = UUID(uuidString: savedUUIDString) {
            logger.info("Restoring active garmin device from saved UUID: \(savedUUID)")
            let device = IQDevice(id: savedUUID, modelName: "", friendlyName: "")
            
            /*If we don't register the device, sensind messages fails with DeviceNotAvailable
             We pass nil because we are not actively monitoring device status yet
             From the documentation: A companion app must register to receive device events before calling methods that
             operate on devices or apps, such as `getDeviceStatus:` or `sendMessage:toApp:progress:completion:`.
             */
            ConnectIQ.sharedInstance().register(forDeviceEvents: device, delegate: nil)
            setActiveGarminDevice(device)
            
        } else {
            logger.info("No Garmin device information found.")
        }
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
        //serviceDelegate?.serviceWantsDeletion(self)
        stateDelegate?.pluginWantsDeletion(self)
    }
    
    
}

extension GarminService: RemoteDataService {
    public func remoteNotificationWasReceived(_ notification: [String : AnyObject]) async throws {
        return
    }

    public func sendMessage(_ message: [String: Any]) {
        //We need to send a message to the garmin device using the ConnectIQ framework. We create a message object with the message data and the app object. We then send the message using the ConnectIQ send message method. We also register for the message progress and completion events
        if let app = self.app {
            self.logger.info("Sending message: \(message)")
            ConnectIQ.sharedInstance().sendMessage(message, to: app, progress: {(sentBytes: UInt32, totalBytes: UInt32) -> Void in
                let percent: Double = 100.0 * Double(sentBytes / totalBytes)
                self.logger.debug("Progress: \(percent)% sent \(sentBytes) bytes of \(totalBytes)")
            }, completion: {(result: IQSendMessageResult) -> Void in
                self.logger.info("Send message finished with result: \(NSStringFromSendMessageResult(result))")
            })}
        else {
            self.logger.info("No garmin aplication set, can't send message")
        }
    }
    
    public func setActiveGarminDevice(_ device: IQDevice?) {
        self.logger.info("Setting active garmin device to \(device ?? nil)")
        //set service app
        if let device = device {
            //TODO: Check if app is installed
            let app = IQApp(uuid: UUID(uuidString: "4e32944d-8bbb-41fd-8318-909efae86ac8"), store: UUID(), device: device)
            self.app = app!
        } else {
            self.app = nil
        }
        self.logger.debug("Set garmin service app to \(self.app)")
        
        // Save the UUID of the device to UserDefaults (or a similar persistent store)
        if let device = device {
            UserDefaults.standard.set(device.uuid.uuidString, forKey: "activeGarminDeviceUUID")
        } else {
            UserDefaults.standard.removeObject(forKey: "activeGarminDeviceUUID")
        }
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
        //self.logger.debug("\(Date()):GarminService.uploadGlucoseData \(stored)")
        if !stored.isEmpty{
            let glucose = stored[0].quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            let date = stored[0].startDate
            let trend = stored[0].trend?.rawValue ?? -1
            self.logger.debug("Sending Glucose: \(glucose) Trend: \(trend) Date: \(date)")
            
            let message = ["glucose": glucose, "trend": trend, "timestamp": Int(date.timeIntervalSince1970)] as [String : Any]
            self.sendMessage(message)
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

