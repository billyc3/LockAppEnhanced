import AppIntents
import Foundation
import SwiftUI
import Security
import LockAppShared

@available(watchOS 11.0, *)
struct StartWorkoutAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Lock Door"
    static var description = IntentDescription("Lock the door when starting a workout")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Lock the door")
    }
    
    static var openAppWhenRun: Bool {
        true
    }
    
    static var isDiscoverable: Bool {
        true
    }
    
    static var authenticationPolicy: IntentAuthenticationPolicy {
        .requiresAuthentication
    }
    
    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
    
    static var dialog: IntentDialog {
        "Locking door..."
    }
    
    static var resultValueName: LocalizedStringResource {
        "Lock Status"
    }
    
    static var resultValueType: String.Type {
        String.self
    }
    
    static var resultValueDescription: LocalizedStringResource {
        "The status of the door lock operation"
    }
    
    static var resultValueSummary: some ParameterSummary {
        Summary("The status of the door lock operation")
    }
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Check if credentials are set with the correct service and accounts
        guard KeychainHelper.areCredentialsSet(service: "LockAppService", accounts: ["apiKey", "deviceId"]) else {
            throw AppIntentError.credentialsNotFound
        }
        
        // Retrieve credentials from Keychain
        guard let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
              let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              let deviceId = String(data: deviceIdData, encoding: .utf8) else {
            throw AppIntentError.credentialsNotFound
        }
        
        // Call lock door functionality with parameters
        try await LockManager.shared.lockDoor(apiKey: apiKey, deviceId: deviceId)
        return .result(value: "Door locked successfully")
    }
    
    enum AppIntentError: Swift.Error {
        case credentialsNotFound
        
        var localizedDescription: String {
            switch self {
            case .credentialsNotFound:
                return "Credentials not found. Please set up your API key and device ID."
            }
        }
    }
}

#if canImport(AppIntents)
extension StartWorkoutAppIntent: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkoutAppIntent(),
            phrases: ["Lock the door with \(.applicationName)"],
            shortTitle: "Lock Door",
            systemImageName: "lock.fill"
        )
    }
}
#endif
