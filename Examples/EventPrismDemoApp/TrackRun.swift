import EventPrism
import Foundation

/// Thread-safe sink buffer. Destinations append mapped payloads; the session folds after idle.
final class PayloadCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var payloads: [DestinationPayload] = []

    func append(_ payload: DestinationPayload) {
        lock.lock()
        payloads.append(payload)
        lock.unlock()
    }

    func clear() {
        lock.lock()
        payloads.removeAll()
        lock.unlock()
    }

    func take() -> [DestinationPayload] {
        lock.lock()
        defer { lock.unlock() }
        let copy = payloads
        payloads.removeAll()
        return copy
    }
}

struct CanonicalInput: Sendable, Equatable {
    var name: String
    var properties: [String: AnalyticsValue]
}

struct MappedEvent: Sendable, Equatable {
    var name: String
    var parameters: [String: AnalyticsValue]
}

enum DestinationOutcome: Sendable, Equatable {
    case received([MappedEvent])
    case skipped(reason: String)
}

struct DestinationTrace: Identifiable, Sendable, Equatable {
    var id: DestinationID
    var outcome: DestinationOutcome
}

struct TrackRun: Sendable, Equatable {
    var input: CanonicalInput
    var destinations: [DestinationTrace]

    static let knownDestinationIDs: [DestinationID] = ["firebase", "braze", "print"]

    static func fold(
        payloads: [DestinationPayload],
        enabledIDs: Set<DestinationID>,
        destinationIDs: [DestinationID] = knownDestinationIDs
    ) -> [DestinationTrace] {
        destinationIDs.map { id in
            if !enabledIDs.contains(id) {
                return DestinationTrace(id: id, outcome: .skipped(reason: "not enabled"))
            }
            let received = payloads.filter { $0.destination == id }.map {
                MappedEvent(name: $0.name, parameters: $0.parameters)
            }
            return DestinationTrace(
                id: id,
                outcome: received.isEmpty ? .skipped(reason: "not in events") : .received(received)
            )
        }
    }
}

enum AnalyticsValueDisplay {
    static func text(_ value: AnalyticsValue) -> String {
        switch value {
        case .string(let text): "\"\(text)\""
        case .int(let number): String(number)
        case .double(let number): String(number)
        case .bool(let flag): flag ? "true" : "false"
        case .null: "null"
        }
    }

    static func jsonObject(_ value: AnalyticsValue) -> Any {
        switch value {
        case .string(let text): text
        case .int(let number): number
        case .double(let number): number
        case .bool(let flag): flag
        case .null: NSNull()
        }
    }

    static func jsonString(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(
                  withJSONObject: object,
                  options: [.prettyPrinted, .sortedKeys]
              ),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return text
    }
}

extension DestinationTrace {
    var wasEnabled: Bool {
        if case .skipped(let reason) = outcome, reason == "not enabled" {
            return false
        }
        return true
    }

    var jsonDisplay: String {
        switch outcome {
        case .skipped(let reason):
            AnalyticsValueDisplay.jsonString([
                "status": "skipped",
                "reason": reason,
            ])
        case .received(let events):
            if events.count == 1 {
                AnalyticsValueDisplay.jsonString(events[0].jsonDictionary)
            } else {
                AnalyticsValueDisplay.jsonString(events.map(\.jsonDictionary))
            }
        }
    }
}

extension MappedEvent {
    var jsonDictionary: [String: Any] {
        var dictionary: [String: Any] = ["name": name]
        for (key, value) in parameters {
            dictionary[key] = AnalyticsValueDisplay.jsonObject(value)
        }
        return dictionary
    }
}
