import WatchConnectivity
import LockAppShared

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private override init() {
        super.init()
        if WCSession.isSupported() {
            print("Session is supported")
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("Session not supported")
        }
    }

    // MARK: - WCSessionDelegate Methods

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        WCSession.default.activate() // Reactivate the session
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WCSession reachability changed: \(session.isReachable ? "reachable" : "not reachable")")
    }

    // MARK: - Sending Messages

    func sendCredentialsToWatch(apiKey: String, deviceId: String) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable. Cannot send credentials.")
            return
        }
        let data = ["apiKey": apiKey, "deviceId": deviceId]
        print("Sending credentials to watch: \(data)")
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("Failed to send credentials: \(error.localizedDescription)")
        }
    }

    // MARK: - Receiving Messages

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("Received message from watch: \(message)")
        if message["request"] as? String == "credentials" {
            if let apiKeyData = KeychainHelper.read(service: "LockAppService", account: "apiKey"),
               let deviceIdData = KeychainHelper.read(service: "LockAppService", account: "deviceId"),
               let apiKey = String(data: apiKeyData, encoding: .utf8),
               let deviceId = String(data: deviceIdData, encoding: .utf8) {
                let response = ["apiKey": apiKey, "deviceId": deviceId]
                print("Sending credentials to watch: \(response)")
                replyHandler(response)
            } else {
                let errorMessage = "Credentials not found"
                print(errorMessage)
                replyHandler(["error": errorMessage])
            }
        }
    }
}
