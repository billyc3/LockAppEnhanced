import SwiftUI
import LockAppShared

struct ContentView: View {
    @State private var credentialsSet = false
    @State private var isFetching = false
    @State private var errorMessage: String?
    @State private var statusMessage = "Ready"
    @State private var isLocked: Bool?

    var body: some View {
        Group {
            if credentialsSet {
                VStack(spacing: 10) {
                    if let isLocked = isLocked {
                        Text(isLocked ? "Locked" : "Unlocked")
                            .font(.headline)
                            .foregroundColor(isLocked ? .red : .green)
                    } else {
                        Text("Checking...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Button("Unlock") { Task { await unlockDoor() } }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button("Lock") { Task { await lockDoor() } }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    Button("Check Status") { Task { await checkLockStatus() } }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    Text(statusMessage)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            } else {
                VStack {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    if isFetching {
                        ProgressView("Fetching...")
                    } else {
                        Button("Fetch Credentials") { fetchCredentials() }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            print("ContentView appeared")
            checkCredentials()
        }
        .onReceive(NotificationCenter.default.publisher(for: .credentialsUpdated)) { _ in
            print("Received credentialsUpdated notification")
            checkCredentials()
        }
    }

    private func checkCredentials() {
        print("Checking credentials...")
        credentialsSet = KeychainHelper.areCredentialsSet()
        print("Credentials set: \(credentialsSet)")
        if credentialsSet {
            print("Fetching lock status...")
            Task {
                await checkLockStatus()
            }
        }
    }

    private func fetchCredentials() {
        print("Fetching credentials...")
        isFetching = true
        errorMessage = nil
        Task {
            do {
                try await WatchConnectivityManager.shared.requestCredentials()
                await MainActor.run {
                    print("Credentials fetched successfully")
                    isFetching = false
                    checkCredentials()
                }
            } catch {
                await MainActor.run {
                    print("Failed to fetch credentials: \(error.localizedDescription)")
                    errorMessage = "Error: \(error.localizedDescription)"
                    isFetching = false
                }
            }
        }
    }

    private func getCredentials() -> (apiKey: String, deviceId: String)? {
        guard let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
              let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
              let apiKey = String(data: apiKeyData, encoding: .utf8),
              let deviceId = String(data: deviceIdData, encoding: .utf8) else {
            return nil
        }
        return (apiKey, deviceId)
    }

    private func unlockDoor() async {
        print("Unlocking door...")
        guard let credentials = getCredentials() else {
            await MainActor.run {
                statusMessage = "Credentials not found"
                print("Credentials not found")
            }
            return
        }
        do {
            try await LockManager.shared.unlockDoor(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
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

    private func lockDoor() async {
        print("Locking door...")
        guard let credentials = getCredentials() else {
            await MainActor.run {
                statusMessage = "Credentials not found"
                print("Credentials not found")
            }
            return
        }
        do {
            try await LockManager.shared.lockDoor(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
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

    private func checkLockStatus() async {
        print("Checking lock status...")
        guard let credentials = getCredentials() else {
            await MainActor.run {
                statusMessage = "Credentials not found"
                print("Credentials not found")
            }
            return
        }
        do {
            let locked = try await LockManager.shared.checkLockStatus(apiKey: credentials.apiKey, deviceId: credentials.deviceId)
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
