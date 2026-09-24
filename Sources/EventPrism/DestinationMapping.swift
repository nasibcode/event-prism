/// From-value cases plus optional reserved `"default"` for one canonical property.
public struct PropertyValueMap: Sendable, Equatable {
    public var cases: [String: AnalyticsValue]
    public var defaultValue: AnalyticsValue?

    public init(cases: [String: AnalyticsValue] = [:], defaultValue: AnalyticsValue? = nil) {
        self.cases = cases
        self.defaultValue = defaultValue
    }
}

/// Parsed `mappings[canonicalName]` from one destination JSON file. Engine-only.
public struct DestinationMapping: Sendable, Equatable {
    public var text: String
    public var keys: [String: String]
    public var values: [String: PropertyValueMap]

    public init(
        text: String,
        keys: [String: String] = [:],
        values: [String: PropertyValueMap] = [:]
    ) {
        self.text = text
        self.keys = keys
        self.values = values
    }
}
