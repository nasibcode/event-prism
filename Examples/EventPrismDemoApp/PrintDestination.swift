import EventPrism

/// Demo sink: appends mapped payloads to the session collector (same protocol as a vendor adapter).
/// `@unchecked Sendable` because the collector is shared with EventPrism’s log hop.
final class PrintDestination: AnalyticsDestination, @unchecked Sendable {
    let id: DestinationID
    private let collector: PayloadCollector

    init(id: DestinationID, collector: PayloadCollector) {
        self.id = id
        self.collector = collector
    }

    func log(_ payload: DestinationPayload) {
        collector.append(payload)
    }
}
