import Foundation
import SwiftUI
import AppIntents
import LockAppShared

class AppLifecycleManager: NSObject {
    // Singleton instance
    static let shared = AppLifecycleManager()
    
    // Private initializer to enforce singleton pattern
    private override init() {
        super.init()
        setupDelegate()
    }
    
    // Set up the delegate for watchOS lifecycle management
    private func setupDelegate() {
        if #available(watchOS 10.0, *) {
            // Delegate is managed through the app lifecycle; implementation provided in extension
        }
    }
    
    // Retrieve API key and device ID from the keychain
    private func getCredentials() -> (apiKey: String, deviceId: String)? {
        // Attempt to read the API key and device ID from the keychain
        guard let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
              let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              let deviceId = String(data: deviceIdData, encoding: .utf8) else {
            return nil
        }
        return (apiKey, deviceId)
    }
}

// Extension for watchOS 10+ lifecycle delegate methods
@available(watchOS 10.0, *)
extension AppLifecycleManager: WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Perform any initialization tasks when the app launches
    }
    
    func applicationDidBecomeActive() {
        // Handle app becoming active, e.g., checking lock status
        Task {
            do {
                if let credentials = getCredentials() {
                    let isLocked = try await LockManager.shared.checkLockStatus(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
                    print("Lock status: \(isLocked)")
                } else {
                    print("Credentials not found in keychain")
                }
            } catch {
                print("Failed to check lock status: \(error.localizedDescription)")
            }
        }
    }
    
    func applicationWillResignActive() {
        // Clean up resources when the app is about to become inactive
    }
    
    func applicationDidEnterBackground() {
        // Handle background state transitions
    }
    
    func handleActionButtonPress() {
        // Handle action button press to unlock the door
        print("Action Button pressed - attempting to unlock door")
        Task {
            do {
                if let credentials = getCredentials() {
                    try await LockManager.shared.unlockDoor(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
                    print("Door unlocked successfully via Action Button")
                } else {
                    print("Credentials not found in keychain")
                }
            } catch {
                print("Failed to unlock door via Action Button: \(error.localizedDescription)")
            }
        }
    }
}
