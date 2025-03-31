import Foundation

/// Represents a device (lock) with its properties.
public struct Device: Identifiable {
    public let device_id: String
    public let properties: DeviceProperties
    public var id: String { device_id } // Conforms to Identifiable
}

/// Represents the properties of a device.
public struct DeviceProperties {
    public let name: String
    public let model: String?
    public let locked: Bool
}

/// Manages lock operations via the Seam API.
public class LockManager: ObservableObject {
    /// Singleton instance of LockManager.
    public static let shared = LockManager()
    
    /// Published property to hold the list of devices, observable by SwiftUI views.
    @Published public var devices: [Device] = []
    
    /// Private initializer to enforce singleton pattern.
    private init() {}
    
    /// Unlocks the door using the provided API key and device ID.
    /// - Parameters:
    ///   - apiKey: The API key for authentication.
    ///   - deviceId: The ID of the device to unlock.
    /// - Throws: An error if the operation fails.
    public func unlockDoor(apiKey: String, deviceId: String) async throws {
        let url = URL(string: "https://connect.getseam.com/locks/unlock_door")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["device_id": deviceId]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LockError.failedToUnlock
        }
    }
    
    /// Locks the door using the provided API key and device ID.
    /// - Parameters:
    ///   - apiKey: The API key for authentication.
    ///   - deviceId: The ID of the device to lock.
    /// - Throws: An error if the operation fails.
    public func lockDoor(apiKey: String, deviceId: String) async throws {
        let url = URL(string: "https://connect.getseam.com/locks/lock_door")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["device_id": deviceId]
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LockError.failedToLock
        }
    }
    
    /// Checks the lock status of the door using the provided API key and device ID.
    /// - Parameters:
    ///   - apiKey: The API key for authentication.
    ///   - deviceId: The ID of the device to check.
    /// - Returns: A boolean indicating whether the door is locked.
    /// - Throws: An error if the operation fails.
    public func checkLockStatus(apiKey: String, deviceId: String) async throws -> Bool {
        let url = URL(string: "https://connect.getseam.com/locks/get?device_id=\(deviceId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LockError.failedToCheckStatus
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let lock = json?["lock"] as? [String: Any],
              let properties = lock["properties"] as? [String: Any],
              let locked = properties["locked"] as? Bool else {
            throw LockError.invalidResponse
        }
        return locked
    }
    
    /// Fetches the list of devices using the provided API key.
    /// - Parameter apiKey: The API key for authentication.
    /// - Returns: An array of Device objects.
    /// - Throws: An error if the operation fails.
    public func getDevices(apiKey: String) async throws -> [Device] {
        let url = URL(string: "https://connect.getseam.com/locks/list")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LockError.failedToFetchDevices
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let locks = json?["locks"] as? [[String: Any]] else {
            throw LockError.invalidResponse
        }
        
        let devices = locks.compactMap { lock in
            if let deviceId = lock["device_id"] as? String,
               let properties = lock["properties"] as? [String: Any],
               let name = properties["name"] as? String,
               let model = properties["model"] as? String,
               let locked = properties["locked"] as? Bool {
                return Device(device_id: deviceId, properties: DeviceProperties(name: name, model: model, locked: locked))
            }
            return nil
        }
        return devices
    }
}

/// Custom error types for lock operations.
public enum LockError: Error {
    case failedToUnlock
    case failedToLock
    case failedToCheckStatus
    case failedToFetchDevices
    case invalidResponse
}
