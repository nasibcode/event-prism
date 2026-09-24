/// Stable destination identifier. Matches a catalog file `"id"` and `AnalyticsDestination.id`.
public struct DestinationID: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}

extension DestinationID: CustomStringConvertible {
    public var description: String { rawValue }
}
