import Foundation
import SwiftUI
import AppIntents
import WatchKit
import LockAppShared

class ExtensionDelegate: NSObject {
    private let connectivityManager = WatchConnectivityManager.shared
    private var backgroundTask: Any?
    
    func applicationDidFinishLaunching() {
        // Initialize any necessary components
        print("App launched - App Intents will be automatically registered")
    }
    
    func applicationDidBecomeActive() {
        Task {
            if let credentials = getCredentials() {
                do {
                    let isLocked = try await LockManager.shared.checkLockStatus(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
                    print("Lock status: \(isLocked)")
                } catch {
                    print("Failed to check lock status: \(error.localizedDescription)")
                }
            } else {
                print("Credentials not found")
            }
        }
    }
    
    func applicationWillResignActive() {
        // Clean up any resources
        if let task = backgroundTask as? WKApplicationRefreshBackgroundTask {
            task.setTaskCompletedWithSnapshot(false)
            backgroundTask = nil
        }
    }
    
    func applicationDidEnterBackground() {
        // Schedule background refresh
        Task {
            do {
                let refreshInfo: [String: String] = ["refreshType": "lockStatus"]
                let userInfo = refreshInfo as NSDictionary
                try await WKApplication.shared().scheduleBackgroundRefresh(
                    withPreferredDate: Date(timeIntervalSinceNow: 15 * 60),
                    userInfo: userInfo,
                    scheduledCompletion: { result in
                        if result == nil {
                            print("Background refresh scheduled successfully")
                        } else {
                            print("Failed to schedule background refresh: \(String(describing: result))")
                        }
                    }
                )
            } catch {
                print("Failed to schedule background refresh: \(error)")
            }
        }
    }
    
    // Handle Action Button press
    func handleActionButtonPress() {
        print("Action Button pressed - attempting to unlock door")
        Task {
            if let credentials = getCredentials() {
                do {
                    try await LockManager.shared.unlockDoor(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
                    print("Door unlocked successfully via Action Button")
                } catch {
                    print("Failed to unlock door via Action Button: \(error.localizedDescription)")
                }
            } else {
                print("Credentials not found")
            }
        }
    }
    
    // Helper function to retrieve credentials from Keychain
    private func getCredentials() -> (apiKey: String, deviceId: String)? {
        guard let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
              let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              let deviceId = String(data: deviceIdData, encoding: .utf8) else {
            return nil
        }
        return (apiKey, deviceId)
    }
}
