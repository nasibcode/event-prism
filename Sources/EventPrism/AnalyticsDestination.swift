/// Client-owned sink. Adapters hold vendor SDKs; this protocol never mentions them.
///
/// `log` must return quickly. Hop off the `EventPrism` actor (for example to the main actor)
/// if the provider requires a specific executor.
public protocol AnalyticsDestination: AnyObject {
    var id: DestinationID { get }

    /// Receives a mapped payload. Must be non-blocking.
    func log(_ payload: DestinationPayload)
}
