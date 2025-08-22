//
//  AWSManager.swift
//  meetX-iOS
//
//  Created by Karthick Thavasimuthu on 26-04-2025.
//

import Foundation
import AWSS3
import AWSCore

final class AWSManager {
    static let shared = AWSManager()
    
    private(set) var isAWSReady: Bool = false
    
    private init() {}
    
    func configureAWS() {
        let credentialsProvider = AWSCognitoCredentialsProvider(
            regionType: .APSouth1,
            identityPoolId: DeveloperConstants.cognitoIdentityPoolId
        )
        
        guard let configuration = AWSServiceConfiguration(region: .APSouth1, credentialsProvider: credentialsProvider) else {
            fatalError("AWS Configuration failed")
        }
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        let transferUtilityConfig = AWSS3TransferUtilityConfiguration()
        transferUtilityConfig.isAccelerateModeEnabled = true
        transferUtilityConfig.retryLimit = 3
        transferUtilityConfig.multiPartConcurrencyLimit = 5
        
        AWSS3TransferUtility.register(
            with: configuration,
            transferUtilityConfiguration: transferUtilityConfig,
            forKey: DeveloperConstants.utilityKey
        ) { [weak self] error in
            if let error = error {
                print("❌ Transfer Utility registration failed: \(error.localizedDescription)")
                self?.isAWSReady = false
            } else {
                print("✅ Transfer Utility registered successfully!")
                self?.isAWSReady = true
            }
        }
    }
}
