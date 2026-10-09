import Foundation

/// Thread-safe flag that lets the mock API simulate being offline.
/// In production this would be backed by `NWPathMonitor`.
final class NetworkState: @unchecked Sendable {
    private let lock = NSLock()
    private var offline: Bool

    init(isOffline: Bool = false) {
        self.offline = isOffline
    }

    var isOffline: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return offline
        }
        set {
            lock.lock()
            offline = newValue
            lock.unlock()
        }
    }
}
