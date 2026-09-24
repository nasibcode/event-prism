/// Looks up a destination's mapping for a canonical event name.
public protocol EventCatalog: Sendable {
    /// Parsed `mappings[eventName]` from that dest’s JSON, or nil if this dest should not receive the event.
    func mapping(for eventName: String, destination: DestinationID) -> DestinationMapping?
}
