/// Merges per-destination catalogs. Prism iterates registered dests; `mapping` nil means skip.
public struct CompositeEventCatalog: EventCatalog, Sendable {
    private let catalogs: [any EventCatalog]

    public init(_ catalogs: any EventCatalog...) {
        self.catalogs = Array(catalogs)
    }

    public init(_ catalogs: [any EventCatalog]) {
        self.catalogs = catalogs
    }

    public func mapping(for eventName: String, destination: DestinationID) -> DestinationMapping? {
        for catalog in catalogs {
            if let mapping = catalog.mapping(for: eventName, destination: destination) {
                return mapping
            }
        }
        return nil
    }
}
