import SwiftUI
import LockAppShared

struct ContentView: View {
    @State private var apiKey = ""
    @State private var deviceId = ""
    @State private var statusMessage = "Ready"
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 20) {
            if isSaving {
                // Credential input mode
                VStack(spacing: 15) {
                    Text("Enter Credentials")
                        .font(.headline)
                        .padding(.bottom, 10)
                    
                    TextField("API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityLabel("API Key")
                    
                    TextField("Device ID", text: $deviceId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityLabel("Device ID")
                    
                    Button(action: {
                        saveToKeychain()
                    }) {
                        Text("Save to Keychain")
                            .font(.system(size: 18, weight: .bold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Save Credentials")
                }
                .padding()
            } else {
                // Main control mode
                VStack(spacing: 15) {
                    Button(action: {
                        Task { await unlockDoor() }
                    }) {
                        Text("Unlock Door")
                            .font(.system(size: 24, weight: .bold))
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .accessibilityLabel("Unlock Door")
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            Task { await lockDoor() }
                        }) {
                            Text("Lock Door")
                                .font(.system(size: 18, weight: .bold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Lock Door")
                        
                        Button(action: {
                            Task { await checkLockStatus() }
                        }) {
                            Text("Check Status")
                                .font(.system(size: 18, weight: .bold))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Check Lock Status")
                    }
                    
                    Text(statusMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        isSaving = true
                    }) {
                        Text("Edit Credentials")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Edit Credentials")
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            loadFromKeychain()
        }
    }

    // MARK: - Keychain and API Functions

    /// Saves API key and device ID to the Keychain
    private func saveToKeychain() {
        guard !apiKey.isEmpty, !deviceId.isEmpty else {
            statusMessage = "Please enter both API Key and Device ID"
            return
        }
        
        guard let apiKeyData = apiKey.data(using: .utf8),
              let deviceIdData = deviceId.data(using: .utf8) else {
            statusMessage = "Error encoding credentials"
            return
        }
        
        do {
            try KeychainHelper.save(apiKeyData, service: "LockAppService", account: "apiKey")
            try KeychainHelper.save(deviceIdData, service: "LockAppService", account: "deviceId")
            statusMessage = "Credentials saved successfully"
            isSaving = false
            
        } catch {
            statusMessage = "Failed to save credentials"
        }
        
        // Sync with Watch App if applicable
        WatchConnectivityManager.shared.sendCredentialsToWatch(apiKey: apiKey, deviceId: deviceId)
    }

    /// Loads credentials from the Keychain on app launch
    private func loadFromKeychain() {
        if let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
           let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
           let loadedApiKey = String(data: apiKeyData, encoding: .utf8),
           let loadedDeviceId = String(data: deviceIdData, encoding: .utf8) {
            apiKey = loadedApiKey
            deviceId = loadedDeviceId
            statusMessage = "Credentials loaded"
            isSaving = false
        } else {
            statusMessage = "Please enter credentials"
            isSaving = true
        }
    }

    /// Unlocks the door using the stored credentials
    private func unlockDoor() async {
        guard !apiKey.isEmpty, !deviceId.isEmpty else {
            statusMessage = "Credentials not set. Please enter credentials."
            isSaving = true
            return
        }
        do {
            try await LockManager.shared.unlockDoor(apiKey: apiKey, deviceId: deviceId)
            await MainActor.run {
                statusMessage = "Door Unlocked!"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Unlock Failed: \(error.localizedDescription)"
            }
        }
    }

    /// Locks the door using the stored credentials
    private func lockDoor() async {
        guard !apiKey.isEmpty, !deviceId.isEmpty else {
            statusMessage = "Credentials not set. Please enter credentials."
            isSaving = true
            return
        }
        do {
            try await LockManager.shared.lockDoor(apiKey: apiKey, deviceId: deviceId)
            await MainActor.run {
                statusMessage = "Door Locked!"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Lock Failed: \(error.localizedDescription)"
            }
        }
    }

    /// Checks the lock status using the stored credentials
    private func checkLockStatus() async {
        guard !apiKey.isEmpty, !deviceId.isEmpty else {
            statusMessage = "Credentials not set. Please enter credentials."
            isSaving = true
            return
        }
        do {
            let locked = try await LockManager.shared.checkLockStatus(apiKey: apiKey, deviceId: deviceId)
            await MainActor.run {
                statusMessage = locked ? "Lock is Locked" : "Lock is Unlocked"
            }
        } catch {
            await MainActor.run {
                statusMessage = "Status Check Failed: \(error.localizedDescription)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
