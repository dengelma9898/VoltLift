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
        self.cancel()
        self.remaining = max(0, durationSeconds)
        self.isRunning = self.remaining > 0
        guard self.isRunning else {
            onCompleted()
            return
        }
        onTick(self.remaining)
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.remaining -= 1
            if self.remaining > 0 {
                onTick(self.remaining)
            } else {
                timer.invalidate()
                self.timer = nil
                self.isRunning = false
                onCompleted()
            }
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
