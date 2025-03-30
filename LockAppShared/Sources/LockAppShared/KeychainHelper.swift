import Foundation
import Security

/// A helper enum for managing credentials in the Keychain.
public enum KeychainHelper {
    /// Saves data to the Keychain for the specified service and account.
    /// - Parameters:
    ///   - data: The data to save (e.g., API key or device ID).
    ///   - service: The service identifier (e.g., "LockAppService").
    ///   - account: The account identifier (e.g., "apiKey" or "deviceId").
    /// - Throws: A `KeychainError` if the save operation fails.
    public static func save(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        // Delete existing item to avoid duplicates
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving to Keychain: \(status)")
            throw KeychainError.saveFailed(status: status)
        }
        print("Saved data to Keychain for service: \(service), account: \(account)")
    }
    
    /// Reads data from the Keychain for the specified service and account.
    /// - Parameters:
    ///   - service: The service identifier (e.g., "LockAppService").
    ///   - account: The account identifier (e.g., "apiKey" or "deviceId").
    /// - Returns: The stored data, or nil if not found.
    public static func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        } else {
            print("Failed to read from Keychain for service: \(service), account: \(account), status: \(status)")
            return nil
        }
    }
    
    /// Checks if both API key and device ID credentials are set in the Keychain.
    /// - Returns: True if both credentials exist, false otherwise.
    public static func areCredentialsSet() -> Bool {
        let apiKeyExists = read(service: "LockAppService", account: "apiKey") != nil
        let deviceIdExists = read(service: "LockAppService", account: "deviceId") != nil
        print("Credentials set - API Key: \(apiKeyExists), Device ID: \(deviceIdExists)")
        return apiKeyExists && deviceIdExists
    }
    
    /// Deletes credentials from the Keychain for the specified service and account.
    /// - Parameters:
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    /// - Throws: A `KeychainError` if deletion fails unexpectedly.
    public static func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error deleting from Keychain: \(status)")
            throw KeychainError.deleteFailed(status: status)
        }
        print("Deleted data from Keychain for service: \(service), account: \(account)")
    }
}

/// Errors that can occur when interacting with the Keychain.
public enum KeychainError: Error {
    case saveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (Status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (Status: \(status))"
        }
    }
}
