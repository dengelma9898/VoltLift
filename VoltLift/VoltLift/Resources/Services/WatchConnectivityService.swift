import Foundation
import WatchConnectivity

final class PhoneWatchConnectivityService: NSObject {
    @MainActor static let shared = PhoneWatchConnectivityService()

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
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        WCSession.default.sendMessage(event, replyHandler: nil, errorHandler: nil)
    }
}

extension PhoneWatchConnectivityService: @preconcurrency WCSessionDelegate {
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}
