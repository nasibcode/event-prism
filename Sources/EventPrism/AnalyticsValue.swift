/// A JSON-friendly analytics property value.
public enum AnalyticsValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    /// String form used for value-map lookup and `${key}` interpolation.
    public var stringified: String {
        switch self {
        case .string(let value):
            value
        case .int(let value):
            String(value)
        case .double(let value):
            String(value)
        case .bool(let value):
            value ? "true" : "false"
        case .null:
            ""
        }
    }
}
