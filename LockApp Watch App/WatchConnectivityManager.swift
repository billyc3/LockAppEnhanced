import WatchConnectivity
import LockAppShared

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    private var isSessionActive = false
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            activateSessionIfNeeded()
        }
    }
    
    private func activateSessionIfNeeded() {
        guard !isSessionActive else { return }
        WCSession.default.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isSessionActive = activationState == .activated
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        }
    }
    
    func requestCredentials() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(["request": "credentials"], replyHandler: { response in
                if let apiKey = response["apiKey"] as? String,
                   let deviceId = response["deviceId"] as? String,
                   let apiKeyData = apiKey.data(using: .utf8),
                   let deviceIdData = deviceId.data(using: .utf8) {
                    do {
                        try KeychainHelper.save(apiKeyData, service: "LockAppService", account: "apiKey")
                        try KeychainHelper.save(deviceIdData, service: "LockAppService", account: "deviceId")
                        NotificationCenter.default.post(name: .credentialsUpdated, object: nil)
                        continuation.resume()
                    } catch {
                        print("Failed to save credentials: \(error)")
                        continuation.resume(throwing: error)
                    }
                } else {
                    let error = NSError(domain: "", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    continuation.resume(throwing: error)
                }
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable ? "reachable" : "not reachable")")
        isSessionActive = session.activationState == .activated
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let apiKey = message["apiKey"] as? String, let deviceId = message["deviceId"] as? String,
           let apiKeyData = apiKey.data(using: .utf8), let deviceIdData = deviceId.data(using: .utf8) {
            do {
                try KeychainHelper.save(apiKeyData, service: "LockAppService", account: "apiKey")
                try KeychainHelper.save(deviceIdData, service: "LockAppService", account: "deviceId")
                NotificationCenter.default.post(name: .credentialsUpdated, object: nil)
            } catch {
                print("Failed to save credentials in didReceiveMessage: \(error)")
                // Optionally, add more error handling here (e.g., notify the user)
            }
        }
    }
}
