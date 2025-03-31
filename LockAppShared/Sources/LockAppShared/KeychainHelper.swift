import Foundation
import Security

/// A helper enum for managing credentials in the Keychain.
public enum KeychainHelper {
    /// Saves data to the Keychain for the specified service and account.
    /// - Note: This method is synchronous and may block the calling thread. Consider using an async version or calling from a background thread for better performance.
    /// - Parameters:
    ///   - data: The data to save (e.g., API key or device ID).
    ///   - service: The service identifier (e.g., "LockAppService").
    ///   - account: The account identifier (e.g., "apiKey" or "deviceId").
    ///   - updateIfExists: If true, updates the existing item instead of deleting it.
    /// - Throws: A `KeychainError` if the save operation fails.
    public static func save(_ data: Data, service: String, account: String, updateIfExists: Bool = false) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        if updateIfExists, read(service: service, account: account) != nil {
            let attributes: [String: Any] = [kSecValueData as String: data]
            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if status != errSecSuccess {
                throw KeychainError.saveFailed(status: status, message: "Update operation failed")
            }
            print("Updated data in Keychain for service: \(service), account: \(account)")
        } else {
            let fullQuery = query.merging([kSecValueData as String: data]) { $1 }
            SecItemDelete(query as CFDictionary) // Delete existing item
            let status = SecItemAdd(fullQuery as CFDictionary, nil)
            if status != errSecSuccess {
                throw KeychainError.saveFailed(status: status, message: "Save operation failed")
            }
            print("Saved data to Keychain for service: \(service), account: \(account)")
        }
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
            throw KeychainError.deleteFailed(status: status, message: "Delete operation failed")
        }
        print("Deleted data from Keychain for service: \(service), account: \(account)")
    }
    
    /// Checks if credentials exist in the Keychain for the specified service and accounts.
    /// - Parameters:
    ///   - service: The service identifier.
    ///   - accounts: An array of account identifiers to check.
    /// - Returns: True if all specified credentials exist, false otherwise.
    public static func areCredentialsSet(service: String, accounts: [String]) -> Bool {
        for account in accounts {
            if read(service: service, account: account) == nil {
                print("Credential missing for service: \(service), account: \(account)")
                return false
            }
        }
        print("All credentials set for service: \(service), accounts: \(accounts)")
        return true
    }
    
    /// Saves a string to the Keychain for the specified service and account.
    /// - Parameters:
    ///   - string: The string to save.
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    /// - Throws: A `KeychainError` if the save operation fails or if string-to-data conversion fails.
    public static func saveString(_ string: String, service: String, account: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.saveFailed(status: -1, message: "Failed to convert string to data")
        }
        try save(data, service: service, account: account)
    }
    
    /// Reads a string from the Keychain for the specified service and account.
    /// - Parameters:
    ///   - service: The service identifier.
    ///   - account: The account identifier.
    /// - Returns: The stored string, or nil if not found or not convertible to UTF-8.
    public static func readString(service: String, account: String) -> String? {
        guard let data = read(service: service, account: account) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

/// Errors that can occur when interacting with the Keychain.
public enum KeychainError: Error {
    case saveFailed(status: OSStatus, message: String)
    case deleteFailed(status: OSStatus, message: String)
    case itemNotFound
    case duplicateItem
    case unexpectedError(status: OSStatus)
    
    init(status: OSStatus) {
        switch status {
        case errSecItemNotFound:
            self = .itemNotFound
        case errSecDuplicateItem:
            self = .duplicateItem
        default:
            self = .unexpectedError(status: status)
        }
    }
}

extension KeychainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status, let message):
            return "Failed to save to Keychain (Status: \(status), Message: \(message))"
        case .deleteFailed(let status, let message):
            return "Failed to delete from Keychain (Status: \(status), Message: \(message))"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .duplicateItem:
            return "Duplicate item found in Keychain"
        case .unexpectedError(let status):
            return "Unexpected Keychain error (Status: \(status))"
        }
    }
}
