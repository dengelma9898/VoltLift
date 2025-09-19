import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif

public protocol HapticsSignaling {
    func signalTimerEnd()
}

public struct HapticsService: HapticsSignaling {
    public init() {}

    public func signalTimerEnd() {
        #if canImport(AudioToolbox)
        // Simpler System-Sound als Fallback, falls CoreHaptics nicht genutzt wird
        AudioServicesPlaySystemSound(1_057) // "ReceivedMessage"-ähnlicher kurzer Ton
        #endif
    }
}
