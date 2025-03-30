import SwiftUI
import LockAppShared

struct ContentView: View {
    @State private var apiKey = ""
    @State private var deviceId = ""
    @State private var statusMessage = "Ready"
    @State private var isSaving = false
    @State private var isLocked = false

    var body: some View {
        VStack(spacing: 20) {
            if isSaving {
                TextField("API Key", text: $apiKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Device ID", text: $deviceId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Save to Keychain") {
                    saveToKeychain()
                }
            } else {
                // Status Card
                VStack(spacing: 8) {
                    Text("Lock Status")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(statusMessage)
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(statusMessage.contains("Locked") ? .green : 
                                      statusMessage.contains("Unlocked") ? .blue : 
                                      .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                Button(action: { unlockDoor() }) {
                    Text("Unlock Door")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                Button(action: { lockDoor() }) {
                    Text("Lock Door")
                        .font(.system(size: 18, weight: .bold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: { checkLockStatus() }) {
                    Text("Check Status")
                        .font(.system(size: 18, weight: .bold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button("Edit Credentials") {
                    isSaving = true
                }
            }
        }
        .padding()
        .onAppear { loadFromKeychain() }
    }

    private func saveToKeychain() {
        guard let apiKeyData = apiKey.data(using: .utf8),
              let deviceIdData = deviceId.data(using: .utf8) else {
            statusMessage = "Error encoding data"
            return
        }
        KeychainHelper.standard.save(apiKeyData, service: "LockAppService", account: "apiKey")
        KeychainHelper.standard.save(deviceIdData, service: "LockAppService", account: "deviceId")
        statusMessage = "Credentials saved"
        isSaving = false
        WatchConnectivityManager.shared.sendCredentialsToWatch(apiKey: apiKey, deviceId: deviceId)
    }

    private func loadFromKeychain() {
        if let apiKeyData = KeychainHelper.standard.read(service: "LockAppService", account: "apiKey"),
           let deviceIdData = KeychainHelper.standard.read(service: "LockAppService", account: "deviceId") {
            apiKey = String(data: apiKeyData, encoding: .utf8) ?? ""
            deviceId = String(data: deviceIdData, encoding: .utf8) ?? ""
            statusMessage = "Credentials loaded"
            isSaving = false
        } else {
            statusMessage = "Please enter credentials"
            isSaving = true
        }
    }

    private func unlockDoor() {
        Task {
            do {
                let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey")
                let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId")
                let apiKey = String(data: apiKeyData, encoding: .utf8),
                let deviceId = String(data: deviceIdData, encoding: .utf8)
                try await LockManager.shared.unlockDoor(apiKey: apiKey, deviceId: deviceId)
                await MainActor.run {
                    statusMessage = "Unlocked!"
                    isLocked = false
                    print("Door unlocked successfully")
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Unlock Failed: \(error.localizedDescription)"
                    print("Failed to unlock door: \(error.localizedDescription)")
                }
            }
        }
    }

    private func lockDoor() {
        Task {
            do {
                let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey")
                let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId")
                let apiKey = String(data: apiKeyData, encoding: .utf8),
                let deviceId = String(data: deviceIdData, encoding: .utf8)
                try await LockManager.shared.unlockDoor(apiKey: apiKey, deviceId: deviceId)
                await MainActor.run {
                    statusMessage = "Locked!"
                    isLocked = true
                    print("Door locked successfully")
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Lock Failed: \(error.localizedDescription)"
                    print("Failed to lock door: \(error.localizedDescription)")
                }
            }
        }
    }

    private func checkLockStatus() {
        Task {
            do {
                let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey")
                let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId")
                let apiKey = String(data: apiKeyData ?? <#default value#>, encoding: .utf8),
                    let deviceId = String(data: deviceIdData ?? <#default value#>, encoding: .utf8)
                let locked = try await LockManager.shared.checkLockStatus(apiKey: apiKey, deviceId: deviceId)
                await MainActor.run {
                    isLocked = locked
                    statusMessage = locked ? "Locked" : "Unlocked"
                    print("Lock status: \(locked ? "Locked" : "Unlocked")")
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Status Error: \(error.localizedDescription)"
                    print("Failed to check lock status: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
