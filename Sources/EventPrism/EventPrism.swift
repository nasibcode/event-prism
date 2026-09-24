import Foundation
import os

/// Vendor-agnostic analytics fan-out. Features call `track`; destinations are registered by the app.
public actor EventPrism {
    private let catalog: any EventCatalog
    private let logger: EventPrismLogging
    private let inflight = InflightCounter()
    private var destinations: [DestinationID: AnalyticsDestination] = [:]

    public init(catalog: any EventCatalog, logger: EventPrismLogging = .default) {
        self.catalog = catalog
        self.logger = logger
    }

    public nonisolated func register(_ destination: AnalyticsDestination) {
        let box = UncheckedTransfer(destination)
        inflight.enter()
        Task {
            await self.store(box.value)
            inflight.leave()
        }
    }

    public nonisolated func unregister(_ id: DestinationID) {
        inflight.enter()
        Task {
            await self.remove(id)
            inflight.leave()
        }
    }

    /// Canonical name + properties. Returns immediately; mapping and `log` run on this actor.
    public nonisolated func track(_ name: String, properties: [String: AnalyticsValue] = [:]) {
        inflight.enter()
        Task {
            await self.deliver(name, properties: properties)
            inflight.leave()
        }
    }

    /// Waits until in-flight register / unregister / track work has finished. Not a vendor SDK flush.
    public func waitUntilIdle() async {
        await inflight.wait()
    }

    private func store(_ destination: AnalyticsDestination) {
        destinations[destination.id] = destination
    }

    private func remove(_ id: DestinationID) {
        destinations.removeValue(forKey: id)
    }

    private func deliver(_ name: String, properties: [String: AnalyticsValue]) {
        for id in destinations.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let destination = destinations[id] else { continue }
            guard let mapping = catalog.mapping(for: name, destination: id) else {
                logger.log(destination: id, eventName: name, message: "skip")
                continue
            }
            let payload = EventTransformer.apply(
                properties: properties,
                mapping: mapping,
                destination: id
            )
            logger.log(destination: id, eventName: name, message: "log \(payload.name)")
            destination.log(payload)
        }
    }
}

private struct UncheckedTransfer<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) {
        self.value = value
    }
}

/// Counts hopped work so `waitUntilIdle` can wait after concurrent `track` calls.
private final class InflightCounter: Sendable {
    private struct State: Sendable {
        var count = 0
        var waiters: [CheckedContinuation<Void, Never>] = []
    }

    private let lock = OSAllocatedUnfairLock(initialState: State())

    func enter() {
        lock.withLock { $0.count += 1 }
    }

    func leave() {
        let pending: [CheckedContinuation<Void, Never>] = lock.withLock { current in
            current.count -= 1
            guard current.count == 0 else { return [] }
            let waiters = current.waiters
            current.waiters.removeAll()
            return waiters
        }
        for waiter in pending {
            waiter.resume()
        }
    }

    func wait() async {
        await withCheckedContinuation { continuation in
            let alreadyIdle = lock.withLock { current -> Bool in
                if current.count == 0 {
                    return true
                }
                current.waiters.append(continuation)
                return false
            }
            if alreadyIdle {
                continuation.resume()
            }
        }
    }
}
