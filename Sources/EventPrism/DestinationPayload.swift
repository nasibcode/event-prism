/// Mapped payload delivered to a destination after transform.
public struct DestinationPayload: Sendable, Equatable {
    public var destination: DestinationID
    public var name: String
    public var parameters: [String: AnalyticsValue]

    public init(
        destination: DestinationID,
        name: String,
        parameters: [String: AnalyticsValue]
    ) {
        self.destination = destination
        self.name = name
        self.parameters = parameters
    }
}
