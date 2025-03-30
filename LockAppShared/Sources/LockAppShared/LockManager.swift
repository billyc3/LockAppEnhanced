import Foundation

public class LockManager {
    public static let shared = LockManager()
    
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
}

/// Custom error types for lock operations.
enum LockError: Error {
    case failedToUnlock
    case failedToLock
    case failedToCheckStatus
    case invalidResponse
}
