import os.log
import LoopKit
import ConnectIQ
import HealthKit
import os
public enum GarminServiceError: Error {
    case incompatibleTherapySettings
    case missingCredentials
}

public final class GarminService: Service {
   
    public var customerToken: String?

    public static let serviceIdentifier = "GarminService"

    public static let localizedTitle = LocalizedString("Garmin", comment: "The title of the Garmin service")
    
    public weak var serviceDelegate: ServiceDelegate?

    public var isOnboarded: Bool
    
    public var app: IQApp?
    
    private let logger : Logger
    
    public init() {
        self.isOnboarded = true
        self.logger = Logger(subsystem: "Garmin", category: "GarminService")
        self.logger.info("GarminService.init")
    }
    

    public required init?(rawState: RawStateValue) {
        self.isOnboarded = rawState["isOnboarded"] as? Bool ?? true   // Backwards compatibility
        self.logger = Logger(subsystem: "Garmin", category: "GarminService")
        self.logger.info("GarminService.init")
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
        serviceDelegate?.serviceDidUpdateState(self)
    }

    public func completeDelete() {
        //try! KeychainManager().setLogglyCustomerToken()
        self.logger.info("GarminService.completeDelete")
        serviceDelegate?.serviceWantsDeletion(self)
        
    }
    
    
}

extension GarminService: RemoteDataService {
    
    func sendMessage(_ message: [String: Any]) {
        //We need to send a message to the garmin device using the ConnectIQ framework. We create a message object with the message data and the app object. We then send the message using the ConnectIQ send message method. We also register for the message progress and completion events
        if let app = self.app {
            self.logger.info("Sending message: \(message)")
            ConnectIQ.sharedInstance().sendMessage(message, to: app, progress: {(sentBytes: UInt32, totalBytes: UInt32) -> Void in
                let percent: Double = 100.0 * Double(sentBytes / totalBytes)
                print("Progress: \(percent)% sent \(sentBytes) bytes of \(totalBytes)")
            }, completion: {(result: IQSendMessageResult) -> Void in
                self.logger.info("Send message finished with result: \(NSStringFromSendMessageResult(result))")
            })}
        else {
            self.logger.info("No garmin aplication set, can't send message")
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
        print("\(Date()):GarminService.uploadGlucoseData \(stored)")
        if !stored.isEmpty{
            let glucose = stored[0].quantity.doubleValue(for: HKUnit(from: "mg/dL"))
            let date = stored[0].startDate
            let trend = stored[0].trend?.rawValue ?? -1
            NSLog("Sending Glucose: \(glucose) Trend: \(trend) Date: \(date)")
            
            let message = ["glucose": glucose, "trend": trend, "timestamp": Int(date.timeIntervalSince1970)] as [String : Any]
            self.sendMessage(message)
        }
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
    
    public var glucoseDataLimit: Int? {return 1}
}

