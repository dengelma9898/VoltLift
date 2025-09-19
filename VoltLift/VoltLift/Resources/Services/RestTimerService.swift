import Foundation

public protocol RestTimerHandling {
    func start(durationSeconds: Int, onTick: @escaping (_ remaining: Int) -> Void, onCompleted: @escaping () -> Void)
    func cancel()
    var isRunning: Bool { get }
}

public final class RestTimerService: RestTimerHandling {
    private var timer: Timer?
    private var remaining: Int = 0
    public private(set) var isRunning: Bool = false

    public init() {}

    public func start(
        durationSeconds: Int,
        onTick: @escaping (_ remaining: Int) -> Void,
        onCompleted: @escaping () -> Void
    ) {
        // Stop any running timer first
        self.cancel()

        // Normalize and store input
        self.remaining = max(0, durationSeconds)
        self.isRunning = self.remaining > 0

        // If there is no time to wait, immediately complete
        guard self.isRunning else {
            onCompleted()
            return
        }

        // Provide an initial value to UI if desired, but avoid per-second ticks
        onTick(self.remaining)

        // Schedule a single-shot timer for the entire remaining duration
        let fireInterval = TimeInterval(self.remaining)
        self.timer = Timer.scheduledTimer(withTimeInterval: fireInterval, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.timer?.invalidate()
            self.timer = nil
            self.isRunning = false
            self.remaining = 0
            onCompleted()
        }

        if let activeTimer = self.timer {
            RunLoop.main.add(activeTimer, forMode: .common)
        }
    }

    public func cancel() {
        self.timer?.invalidate()
        self.timer = nil
        self.isRunning = false
        self.remaining = 0
    }
}
