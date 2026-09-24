import Foundation

/// Errors thrown by `JSONDestinationCatalog` when `strict` is true.
public enum JSONDestinationCatalogError: Error, Equatable, Sendable {
    case invalidJSON
    case invalidSchema(String)
}

/// Parses **one** destination catalog file (`schemaVersion`, `id`, `events`, `mappings`).
public struct JSONDestinationCatalog: EventCatalog {
    public let id: DestinationID

    private let events: [String: Bool]
    private let mappings: [String: DestinationMapping]
    private let dropped: Bool

    /// Loads a destination file from disk.
    ///
    /// Invalid JSON or schema: if `strict` is false, this dest drops all events (log once);
    /// if `strict` is true, throws.
    public init(url: URL, strict: Bool = false, logger: EventPrismLogging = .default) throws {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            if strict {
                throw JSONDestinationCatalogError.invalidJSON
            }
            logger.log(message: "invalid catalog at \(url.lastPathComponent); dropping destination")
            self.init(dropped: true)
            return
        }
        try self.init(data: data, strict: strict, logger: logger)
    }

    /// Parses catalog bytes. Same drop-all vs `strict` rules as `init(url:)`.
    public init(data: Data, strict: Bool = false, logger: EventPrismLogging = .default) throws {
        do {
            try self.init(parsed: Self.decode(data))
        } catch {
            if strict {
                throw error as? JSONDestinationCatalogError ?? .invalidJSON
            }
            logger.log(message: "invalid catalog JSON; dropping destination")
            self.init(dropped: true)
        }
    }

    private init(parsed: ParsedFile) {
        self.id = parsed.id
        self.events = parsed.events
        self.mappings = parsed.mappings
        self.dropped = false
    }

    private init(dropped: Bool) {
        self.id = DestinationID(rawValue: "")
        self.events = [:]
        self.mappings = [:]
        self.dropped = dropped
    }

    public func mapping(for eventName: String, destination: DestinationID) -> DestinationMapping? {
        guard !dropped, destination == id else { return nil }
        guard events[eventName] == true else { return nil }
        return mappings[eventName]
    }

    private struct ParsedFile {
        var id: DestinationID
        var events: [String: Bool]
        var mappings: [String: DestinationMapping]
    }

    private static func decode(_ data: Data) throws -> ParsedFile {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw JSONDestinationCatalogError.invalidJSON
        }
        guard let root = object as? [String: Any] else {
            throw JSONDestinationCatalogError.invalidSchema("root must be an object")
        }
        guard let rawID = root["id"] as? String, !rawID.isEmpty else {
            throw JSONDestinationCatalogError.invalidSchema("missing id")
        }
        let events = decodeEvents(root["events"])
        let rawMappings = (root["mappings"] as? [String: Any]) ?? [:]
        var mappings: [String: DestinationMapping] = [:]
        mappings.reserveCapacity(rawMappings.count)
        for (name, value) in rawMappings {
            guard let body = value as? [String: Any] else {
                throw JSONDestinationCatalogError.invalidSchema("mappings.\(name) must be an object")
            }
            guard let text = body["text"] as? String else {
                throw JSONDestinationCatalogError.invalidSchema("mappings.\(name) missing text")
            }
            let keys = (body["keys"] as? [String: String]) ?? [:]
            let rawValues = (body["values"] as? [String: Any]) ?? [:]
            var values: [String: PropertyValueMap] = [:]
            for (propertyKey, mapObject) in rawValues {
                guard let map = mapObject as? [String: Any] else {
                    throw JSONDestinationCatalogError.invalidSchema("values.\(propertyKey) must be an object")
                }
                values[propertyKey] = decodeValueMap(map)
            }
            mappings[name] = DestinationMapping(text: text, keys: keys, values: values)
        }
        return ParsedFile(id: DestinationID(rawValue: rawID), events: events, mappings: mappings)
    }

    private static func decodeEvents(_ raw: Any?) -> [String: Bool] {
        guard let object = raw as? [String: Any] else { return [:] }
        var events: [String: Bool] = [:]
        for (key, value) in object {
            switch value {
            case let flag as Bool:
                events[key] = flag
            case let number as NSNumber:
                events[key] = number.boolValue
            default:
                break
            }
        }
        return events
    }

    private static func decodeValueMap(_ object: [String: Any]) -> PropertyValueMap {
        var cases: [String: AnalyticsValue] = [:]
        var defaultValue: AnalyticsValue?
        for (fromValue, raw) in object {
            let value = decodeAnalyticsValue(raw)
            if fromValue == "default" {
                defaultValue = value
            } else {
                cases[fromValue] = value
            }
        }
        return PropertyValueMap(cases: cases, defaultValue: defaultValue)
    }

    private static func decodeAnalyticsValue(_ raw: Any) -> AnalyticsValue {
        switch raw {
        case let value as String:
            return .string(value)
        case is NSNull:
            return .null
        case let value as NSNumber:
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                return .bool(value.boolValue)
            }
            let doubleValue = value.doubleValue
            if let intValue = Int(exactly: doubleValue), doubleValue == Double(intValue) {
                return .int(intValue)
            }
            return .double(doubleValue)
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        default:
            return .string(String(describing: raw))
        }
    }
}
