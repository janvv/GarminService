//
//  NightscoutService.swift
//  NightscoutServiceKit
//
//  Created by Darin Krauss on 6/20/19.
//  Copyright © 2019 LoopKit Authors. All rights reserved.
//

import os.log
import HealthKit
import LoopKit

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

    public init() {
        self.isOnboarded = false
    }

    public required init?(rawState: RawStateValue) {
        self.isOnboarded = rawState["isOnboarded"] as? Bool ?? true   // Backwards compatibility
    }

    public var rawState: RawStateValue {
        return [
            "isOnboarded": isOnboarded,
        ]
    }
    
}

extension GarminService: RemoteDataService {
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
        print("GarminService.uploadGlucoseData")
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

