import Foundation
import os

/// In-memory destination for tests. Thread-safe so `log` can run on the EventPrism actor.
public final class RecordingDestination: AnalyticsDestination, Sendable {
    public let id: DestinationID

    private struct State: Sendable {
        var stored: [DestinationPayload] = []
        var waiters: [(count: Int, continuation: CheckedContinuation<[DestinationPayload], Never>)] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    public init(id: DestinationID) {
        self.id = id
    }

    public func log(_ payload: DestinationPayload) {
        let snapshotAndReady: ([DestinationPayload], [CheckedContinuation<[DestinationPayload], Never>]) =
            state.withLock { current in
                current.stored.append(payload)
                let snapshot = current.stored
                let ready = current.waiters.filter { snapshot.count >= $0.count }.map(\.continuation)
                current.waiters.removeAll { snapshot.count >= $0.count }
                return (snapshot, ready)
            }
        for waiter in snapshotAndReady.1 {
            waiter.resume(returning: snapshotAndReady.0)
        }
    }

    /// Payloads received so far, in order.
    public var payloads: [DestinationPayload] {
        state.withLock { $0.stored }
    }

    /// Suspends until at least `count` payloads have been logged.
    public func waitUntilCount(_ count: Int) async -> [DestinationPayload] {
        await withCheckedContinuation { continuation in
            let immediate: [DestinationPayload]? = state.withLock { current in
                if current.stored.count >= count {
                    return current.stored
                }
                current.waiters.append((count: count, continuation: continuation))
                return nil
            }
            if let immediate {
                continuation.resume(returning: immediate)
            }
        }
    }
}
