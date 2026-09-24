import EventPrism
import Foundation
import Observation

@Observable @MainActor
final class DemoSession {
    struct CatalogEvent: Identifiable, Hashable {
        var id: String { name }
        var name: String
        var title: String
    }

    private let collector = PayloadCollector()
    private(set) var lastRun: TrackRun?
    private(set) var loadError: String?
    private(set) var isReady = false
    private(set) var isRunning = false
    private(set) var registeredIDs: Set<DestinationID> = []
    private(set) var events: [CatalogEvent] = []

    var selectedEventName: String?
    /// Per-event dest selection. Empty means Track is disabled. Not the JSON catalog `events` map.
    var eventDestinations: [String: Set<DestinationID>] = [:]

    let knownDestinationIDs = TrackRun.knownDestinationIDs

    private var prism: EventPrism?
    private var adapters: [DestinationID: PrintDestination] = [:]

    init() {
        Task { await boot() }
    }

    var canTrack: Bool {
        guard isReady, !isRunning, let name = selectedEventName else { return false }
        return !(eventDestinations[name] ?? []).isEmpty
    }

    func sampleProperties(for name: String) -> [String: AnalyticsValue] {
        Self.sampleProperties(for: name)
    }

    func mergedSampleProperties(
        for name: String,
        extras: [(key: String, value: String)]
    ) -> [String: AnalyticsValue] {
        Self.mergedSampleProperties(for: name, extras: extras)
    }

    func isRegistered(_ id: DestinationID) -> Bool {
        registeredIDs.contains(id)
    }

    func destinations(for eventName: String) -> Set<DestinationID> {
        eventDestinations[eventName] ?? []
    }

    func toggleEventDestination(_ id: DestinationID, for eventName: String) {
        var current = eventDestinations[eventName] ?? []
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        eventDestinations[eventName] = current
    }

    func toggleDestination(_ id: DestinationID) async {
        guard isReady, let prism, let adapter = adapters[id] else { return }
        if registeredIDs.contains(id) {
            prism.unregister(id)
            registeredIDs.remove(id)
        } else {
            prism.register(adapter)
            registeredIDs.insert(id)
        }
        await prism.waitUntilIdle()
    }

    func trackSelected(extras: [(key: String, value: String)] = []) async {
        guard isReady, !isRunning, let prism, let name = selectedEventName else { return }
        let selected = eventDestinations[name] ?? []
        guard !selected.isEmpty else { return }

        isRunning = true
        defer { isRunning = false }

        collector.clear()
        let snapshot = registeredIDs
        for id in selected {
            if let adapter = adapters[id] {
                prism.register(adapter)
            }
        }
        for id in snapshot where !selected.contains(id) {
            prism.unregister(id)
        }
        await prism.waitUntilIdle()

        let properties = Self.mergedSampleProperties(for: name, extras: extras)
        prism.track(name, properties: properties)
        await prism.waitUntilIdle()

        for id in TrackRun.knownDestinationIDs {
            if snapshot.contains(id) {
                if let adapter = adapters[id] {
                    prism.register(adapter)
                }
            } else {
                prism.unregister(id)
            }
        }
        await prism.waitUntilIdle()
        registeredIDs = snapshot

        lastRun = TrackRun(
            input: CanonicalInput(name: name, properties: properties),
            destinations: TrackRun.fold(payloads: collector.take(), enabledIDs: selected)
        )
    }

    private func boot() async {
        do {
            let loaded = try Self.loadCatalogs()
            let prism = EventPrism(catalog: loaded.catalog)
            var adapters: [DestinationID: PrintDestination] = [:]
            for id in TrackRun.knownDestinationIDs {
                adapters[id] = PrintDestination(id: id, collector: collector)
            }
            self.prism = prism
            self.adapters = adapters
            events = Self.makeEventList(names: loaded.eventNames)
            isReady = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    private static func makeEventList(names: Set<String>) -> [CatalogEvent] {
        let catalogEvents = names.sorted().map { CatalogEvent(name: $0, title: $0) }
        let unknown = CatalogEvent(name: "not_a_real_event", title: "Unknown event")
        return catalogEvents + [unknown]
    }

    static func mergedSampleProperties(
        for name: String,
        extras: [(key: String, value: String)]
    ) -> [String: AnalyticsValue] {
        var merged = sampleProperties(for: name)
        for extra in extras {
            let key = extra.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            merged[key] = parseCustomPropertyValue(extra.value)
        }
        return merged
    }

    static func parseCustomPropertyValue(_ raw: String) -> AnalyticsValue {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "true" { return .bool(true) }
        if trimmed == "false" { return .bool(false) }
        if let int = Int(trimmed), String(int) == trimmed {
            return .int(int)
        }
        return .string(raw)
    }

    static func sampleProperties(for name: String) -> [String: AnalyticsValue] {
        switch name {
        case "screen_viewed":
            [
                "page_name": .string("home"),
                "page_title": .string("Welcome"),
            ]
        case "item_tapped":
            [
                "item_id": .string("sku-1"),
                "extra": .string("keep"),
            ]
        case "checkout_started":
            [
                "currency": .string("USD"),
                "value": .double(12.5),
            ]
        case "debug_only":
            ["note": .string("dev")]
        case "promo_seen":
            ["id": .string("p1")]
        default:
            [:]
        }
    }

    private struct LoadedCatalogs {
        var catalog: CompositeEventCatalog
        var eventNames: Set<String>
    }

    private static func loadCatalogs() throws -> LoadedCatalogs {
        let urls = try [
            catalogURL("firebase"),
            catalogURL("braze"),
            catalogURL("print"),
        ]
        let catalogs = try urls.map { try JSONDestinationCatalog(url: $0, strict: true) }
        var names: Set<String> = []
        for url in urls {
            names.formUnion(try eventNames(in: url))
        }
        return LoadedCatalogs(
            catalog: CompositeEventCatalog(catalogs),
            eventNames: names
        )
    }

    private static func eventNames(in url: URL) throws -> Set<String> {
        let data = try Data(contentsOf: url)
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }
        var names: Set<String> = []
        if let events = root["events"] as? [String: Any] {
            names.formUnion(events.keys)
        }
        if let mappings = root["mappings"] as? [String: Any] {
            names.formUnion(mappings.keys)
        }
        return names
    }

    private static func catalogURL(_ name: String) throws -> URL {
        if let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Catalogs")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
        {
            return url
        }
        throw CatalogLoadError.missing(name)
    }
}

private enum CatalogLoadError: Error, LocalizedError {
    case missing(String)

    var errorDescription: String? {
        switch self {
        case .missing(let name):
            "Missing catalog \(name).json in the app bundle."
        }
    }
}
