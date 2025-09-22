import Foundation
import WatchConnectivity

final class WatchConnectivityService: NSObject {
    static let shared = WatchConnectivityService()

    override private init() {
        super.init()
    }

    func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(event: [String: Any]) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(event, replyHandler: nil, errorHandler: nil)
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // No-op for now
    }

    #if os(watchOS)
    func sessionReachabilityDidChange(_ session: WCSession) {
        // No-op for now
    }
    #endif
}
