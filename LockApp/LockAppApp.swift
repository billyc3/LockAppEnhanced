//
//  LockApp2App.swift
//  LockApp2
//
//  Created by William Cook on 3/24/25.
//

import SwiftUI
import LockAppShared
import AppIntents


@main
struct LockAppApp: App {
    

    
    // Initialize the connectivity manager
    let connectivityManager = WatchConnectivityManager.shared
    var body: some Scene {
        WindowGroup {
            ContentView()

        }
    }
    


}

@available(iOS 16.0, *)
public struct UnlockDoorIntent: AppIntent {
    public static var title: LocalizedStringResource = "Unlock Door"
    public static var description = IntentDescription("Unlocks the back door.")
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    public static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard KeychainHelper.areCredentialsSet(service: "LockAppService", accounts: ["apiKey", "deviceId"]) else {
            return .result(value: "Failed", dialog: IntentDialog("Credentials not found. Set up your API key and device ID."))
        }
        
        guard let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
              let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              let deviceId = String(data: deviceIdData, encoding: .utf8) else {
            return .result(value: "Failed", dialog: IntentDialog("Failed to retrieve credentials."))
        }
        
        try await LockManager.shared.unlockDoor(apiKey: apiKey, deviceId: deviceId)
        return .result(value: "Success", dialog: IntentDialog("Door unlocked successfully"))
    }
    
    public init() {}
}

